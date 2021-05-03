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

const ARCHIVE_FETCHER = "builtins.fetchTarball"
const GIT_FETCHER = "fetchgit"
const JULIA_PKG_FETCHER = joinpath(@__DIR__, "./fetch-julia-package.nix")
const JULIA_ARTIFACT_FETCHER = joinpath(@__DIR__, "./fetch-julia-artifact.nix")



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
            rethrow(e)
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
                # @info "DID TAKE RESULT"
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

function flatten_artifacts(pkgs::Vector{PackageInfo})
    flat    = Dict{SHA1,Vector{ArtifactInfo}}()
    skipped = Dict{SHA1,Vector{ArtifactInfo}}()
    for pkg in pkgs, (name, artifacts) in pkg.artifacts, artifact in artifacts
        dict = artifact.fetcher === nothing ? skipped : flat
        hash = artifact.tree_hash
        haskey(dict, hash) || (dict[hash] = ArtifactInfo[])
        push!(dict[hash], artifact)
    end
    return flat, skipped
end

# TODO pass in registries
function generate(package)
    opts = Options(
        nworkers = 8,
        arch = Set(["x86_64"]),
        os =   Set(["linux"]),
        libc = Set(["glibc"]),
    )

    Pkg.Operations.with_temp_env(package) do
        ctx = Context()
        pkgs = load_infos(ctx)
        # select_pkg_fetchers!(pkgs, opts)
        select_artifact_fetchers!(pkgs, opts)
        flat, skipped = flatten_artifacts(pkgs)
    end
end

end

sources = M.generate(joinpath(@__DIR__, "../testenv"));
nothing

