module M

# NOTE
# Nix sha256 is base-32 encoded
# Artifact sha256 is base-16 encoded
#   nix-hash --type sha256 --to-base16 <HASH>

using Pkg
using Pkg: pkg_server
using Pkg.Types: Context, RegistrySpec, VersionNumber
using Pkg.MiniProgressBars
using TOML
using HTTP
using Base: UUID, SHA1
using NixSourcerer


const FLAKE_PATH = joinpath(@__DIR__, "../default.nix")
const ARCHIVE_FETCHER = "builtins.fetchTarball"
const GIT_FETCHER = "pkgs.fetchgit"
const JULIA_PKG_FETCHER = "pkgs.juliaPlatform.fetchJuliaPackage" 
const JULIA_ARTIFACT_FETCHER = "pkgs.juliaPlatform.fetchJuliaArtifact" 


include("./types.jl")
include("./util.jl")


function load_artifacts!(pkginfo::PackageInfo)
    artifacts_file = Pkg.Artifacts.find_artifacts_toml(joinpath(pkginfo.depot, pkginfo.path))
    if artifacts_file !== nothing
        artifacts_meta = TOML.parsefile(artifacts_file)
        for (name, metas) in artifacts_meta
            if metas isa AbstractDict
                metas = [metas]
            end
            pkginfo.artifacts[name] = ArtifactInfo[]
            for meta in metas
                artifactinfo = ArtifactInfo(;
                    name,
                    tree_hash = SHA1(meta["git-tree-sha1"]),
                    arch      = get(meta, "arch", nothing),
                    os        = get(meta, "os", nothing),
                    libc      = get(meta, "libc", nothing),
                    lazy      = get(meta, "lazy", false),
                    downloads = map(d -> (url=d["url"], sha256=d["sha256"]), get(meta, "downloads", []))
                )
                push!(pkginfo.artifacts[name], artifactinfo)
            end
        end
    end
    return pkginfo
end

function load_registry_info!(infos::Vector{PackageInfo})
    for registry in Pkg.Types.collect_registries()
        known = TOML.parsefile(joinpath(registry.path, "Registry.toml"))["packages"]
        for info in infos
            if info.is_tracking_registry
                uuid = string(info.uuid)
                if haskey(known, uuid) 
                    repo = TOML.parsefile(joinpath(registry.path, known[uuid]["path"], "Package.toml"))["repo"]
                    push!(info.repos, repo)
                    push!(info.registries, registry) 
                end
            end
        end
    end
    return infos
end

function load_infos(ctx::Context)
    alldeps = Pkg.dependencies(ctx)
    infos = PackageInfo[]
    for (uuid, pkg) in alldeps
        # TODO version from Project.toml?
        if Pkg.Types.is_stdlib(uuid, VERSION)
            continue
        elseif pkg.is_tracking_path
            error("Package $(pkg.name) ($(uuid)) is tracking a path")
        else
            tree_hash = SHA1(pkg.tree_hash)
            depot, path = get_source_path(ctx, pkg.name, uuid, tree_hash)
            info = PackageInfo(; 
                uuid, 
                pkg.name, 
                pkg.version,
                tree_hash, 
                depot,
                path,
                pkg.is_tracking_path,
                pkg.is_tracking_repo,
                pkg.is_tracking_registry
            )

            if pkg.is_tracking_repo
                push!(info.repos, pkg.git_source)
            end

            load_artifacts!(info)
            
            push!(infos, info)
        end
    end

    load_registry_info!(infos)

    return infos 
end


function select_fetcher(fetchers::Vector{Fetcher})
    for fetcher in fetchers 
        try
            fetcher.args["sha256"] = fetch_sha256(fetcher) 
            return fetcher
        catch e
            @info "Fetcher failed: $fetcher\n$(sprint(showerror, e))"
            continue
        end
    end
    return nothing
end

const FetcherResult = Union{Fetcher,Nothing}
function select_fetchers(allfetchers::Dict{K,Vector{Fetcher}}, nworkers::Int) where {K}
    jobs = Channel{Tuple{K,Vector{Fetcher}}}(nworkers)
    results = Channel{Tuple{K,FetcherResult}}(nworkers)
    @sync begin
        # writer
        @async begin
            for (key, fetchers) in allfetchers 
                put!(jobs, (key, fetchers))
            end
        end
       
        # readers
        for i in 1:nworkers
            @async begin
                for (key, fetchers) in jobs
                    fetcher = select_fetcher(fetchers)
                    put!(results, (key, fetcher))
                end
            end
        end

        bar = MiniProgressBar(; indent=2, header = "Progress", color = Base.info_color(),
                                percentage=false, always_reprint=true, max = length(allfetchers))
        try
            start_progress(stdout, bar)
            selected = Dict{K,FetcherResult}()
            for i=1:length(allfetchers)
                bar.current = i

                key, fetcher = take!(results)
                selected[key] = fetcher

                # print_progress_bottom(stdout)
                show_progress(stdout, bar)
            end
            return selected 
        finally
            end_progress(stdout, bar)
            close(jobs)
            close(results)
        end
    end
end

function select_pkg_fetchers!(infos::Vector{PackageInfo}, opts::Options) 
    allfetchers = Dict{PackageInfo,Vector{Fetcher}}()

    for info in infos 
        fetchers = Fetcher[]
        if opts.pkg_server !== nothing
            push!(fetchers, Fetcher(JULIA_PKG_FETCHER, 
                Dict("uuid" => info.uuid, "treeHash" => info.tree_hash, "server" => opts.pkg_server)))
        end
        for url in info.archives 
            push!(fetchers, Fetcher(ARCHIVE_FETCHER, Dict("url", info.url))) 
        end
        for repo in info.repos 
            push!(fetchers, Fetcher(GIT_FETCHER, Dict("url" => repo, "rev" => info.tree_hash)))
        end
        allfetchers[info] = fetchers
    end
    
    selected = select_fetchers(allfetchers, opts.nworkers)
    for (info, fetcher) in selected
        if fetcher === nothing
            error("Package with UUID '$(info.uuid)' has no sources")
        else
            info.fetcher = fetcher
        end
    end

    return selected
end

function is_artifact_required(artifact_info::ArtifactInfo, opts::Options)
    lazy_matches   = !(artifact_info.lazy && !opts.lazy_artifacts)
    system_matches = ((opts.arch === nothing || artifact_info.arch in opts.arch)
                   && (opts.os   === nothing || artifact_info.os   in opts.os)
                   && (opts.libc === nothing || artifact_info.libc in opts.libc))
    return lazy_matches && system_matches
end

function select_artifact_fetchers!(pkgs::Vector{PackageInfo}, opts::Options)
    tofetch = Dict{ArtifactInfo,Vector{Fetcher}}()
    for pkg in pkgs, (artifact_name, artifact_infos) in pkg.artifacts, artifact_info in artifact_infos
        if !is_artifact_required(artifact_info, opts)
            continue
        elseif opts.pkg_server !== nothing
            url = "$(opts.pkg_server)/artifact/$(artifact_info.tree_hash)"
            if isvalid_url(url)
                # Prefer using Pkg server even though we don't have a sha256
                tofetch[artifact_info] = [Fetcher(JULIA_ARTIFACT_FETCHER, Dict(
                    "treeHash" => artifact_info.tree_hash, 
                    "server" => opts.pkg_server
                ))]
                continue
            else
                @info "URL Invalid: $url"
            end
        elseif isempty(artifact_info.downloads)
            @info "Artifact $artifact_name ($(artifact_info.tree_hash)) has no downloads"
            continue
        else
            for dl in artifact_info.downloads
                if isvalid_url(dl.url)
                    artifact_info.fetcher = Fetcher(ARCHIVE_FETCHER, Dict(
                        "url", dl.url, 
                        "sha256", dl.sha256
                    ))
                    break
                else
                    @info "URL Invalid: $url"
                end
            end
        end
    end
    
    selected = select_fetchers(tofetch, opts.nworkers)
    for (artifact_info, fetcher) in selected 
        if fetcher !== nothing
            # prefer to use the Pkg server
            artifact_info.fetcher = fetcher
        end
        @assert artifact_info.fetcher !== nothing
    end

    return pkgs
end

function merge_paths(pkgs::Vector{PackageInfo})
    merged_pkgs = Dict{String,PackageInfo}()
    merged_artifacts = Dict{String,ArtifactInfo}()
    for pkg in pkgs
        @assert !haskey(merged_pkgs, pkg.path)
        merged_pkgs[pkg.path] = pkg

        for (name, artifacts) in pkg.artifacts, artifact in artifacts
            haskey(merged_artifacts, artifact.path) && continue
            artifact.fetcher === nothing && continue
            merged_artifacts[artifact.path] = artifact
        end
    end
    return (pkgs = merged_pkgs, artifacts = merged_artifacts) 
end


function write_depot(pkgs::Vector{PackageInfo}, opts::Options, package_path::String)
    # depot_path -> src
    depot = Dict{String,Any}()
    merged = merge_paths(pkgs)

    io = IOBuffer(append=true)
    write(io, "{ pkgs ? import <nixpkgs> {} }: {\n")
    for path in sort(collect(keys(merged.pkgs)))
        pkg = merged.pkgs[path]
        Nix.print(io, path)
        write(io, " = (")
        Nix.print(io, pkg.fetcher)
        write(io, ");\n")
    end
    for path in sort(collect(keys(merged.artifacts)))
        artifact = merged.artifacts[path]
        Nix.print(io, path)
        write(io, " = (")
        Nix.print(io, artifact.fetcher)
        write(io, ");\n")
    end
    write(io, '}')

    depotfile_path = normpath(joinpath(package_path, "Depot.nix"))
    if ispath(depotfile_path) && !opts.force_overwrite 
        error("$depotfile_path already exists!")
    else
        @info "Writing depot to $depotfile_path"
        open(normpath(joinpath(package_path, "Depot.nix")), "w") do f
            Nix.nixfmt(f, io)
        end
    end
end

# TODO pass in registries
function generate_depot(package_path::String, opts::Options = Options())
    opts = Options(
        nworkers = 16,
        arch = Set(["x86_64"]),
        os =   Set(["linux"]),
        libc = Set(["glibc"]),
        force_overwrite = true
    )

    Pkg.Operations.with_temp_env(package_path) do
        ctx = Context()
        pkgs = load_infos(ctx)
        select_pkg_fetchers!(pkgs, opts)
        select_artifact_fetchers!(pkgs, opts)
        return write_depot(pkgs, opts, package_path)
    end
end

end

x = M.generate_depot(joinpath(@__DIR__, "../testenv"));
nothing

