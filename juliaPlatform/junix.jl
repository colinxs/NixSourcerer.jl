module M

using Pkg
using Pkg: pkg_server
using Pkg.Types: Context, RegistrySpec, VersionNumber
using Pkg.MiniProgressBars
using TOML
using Base: UUID, SHA1
using NixSourcerer

const ARCHIVE_FETCHER = "builtins.fetchTarball"
const GIT_FETCHER = "fetchgit"
const JULIA_PKG_FETCHER = joinpath(@__DIR__, "./fetch-julia-package.nix")

struct Fetcher
    name::String
    args::Dict{String,Any}
end

Base.@kwdef mutable struct PackageInfo
    uuid::UUID
    name::String
    version::VersionNumber
    tree_hash::SHA1
    depot::String
    path::String
    is_tracking_path::Bool
    is_tracking_repo::Bool
    is_tracking_registry::Bool
    registries::Vector{RegistrySpec} = RegistrySpec[]
    artifacts::Dict{String,Any} = Dict{String,Any}()
    repos::Vector{String} = String[]
    archives::Vector{String} = String[]
    fetcher::Union{Fetcher,Nothing} = nothing 
end

using NixSourcerer: Source, Nix

# TODO move to NixSourcerer?
function get_archive_url_for_version(url::String, ref)
    if (m = match(r"https://github.com/(.*?)/(.*?).git", url)) !== nothing
        return "https://api.github.com/repos/$(m.captures[1])/$(m.captures[2])/tarball/$(ref)"
    end
    return nothing
end

function get_pkg_url(uuid::UUID, tree_hash::String)
    if (server = pkg_server()) !== nothing
        return "$server/package/$(uuid)/$(tree_hash)"
    end
end

function get_source_path(ctx::Context, name::String, uuid::UUID, tree_hash::SHA1) 
    spec = Pkg.Types.PackageSpec(; name, uuid, tree_hash)
    path = Pkg.Operations.source_path(ctx, spec)
    for depot in DEPOT_PATH
        if startswith(normpath(path), normpath(depot))
            return depot, relpath(normpath(path), normpath(depot))
        end
    end
    return nothing
end

function load_artifacts!(info::PackageInfo)
    artifacts_file = Pkg.Artifacts.find_artifacts_toml(joinpath(info.depot, info.path))
    if artifacts_file !== nothing
        for (k, v) in TOML.parsefile(artifacts_file)
            info.artifacts[k] = v
        end
    end
    return info
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

function fetch_sha256(fetcher::Fetcher)
    args = String[]
    for (k, v) in fetcher.args
        push!(args, "--$(k)")
        push!(args, string(v))
    end
    cmd = `nix-prefetch $(fetcher.name) --hash-algo sha256 --output raw $(args)`
    return strip(read(pipeline(cmd, stderr=devnull), String))
end


gen_name(pkg::PackageInfo) = "$(pkg.name)-$(pkg.version)"

function load_fetchers!(ctx::Context, infos::Vector{PackageInfo}; ntasks::Integer = 4) 
    Base.Experimental.@sync begin
    # @sync begin
        # TODO typed
        jobs = Channel(ntasks)
        results = Channel(ntasks)

        @async begin
            for info in infos 
                fetchers = Fetcher[]
                
                push!(fetchers, Fetcher(JULIA_PKG_FETCHER, Dict("uuid" => info.uuid, "treeHash" => info.tree_hash)))
                for url in info.archives 
                    push!(fetchers, Fetcher(ARCHIVE_FETCHER, Dict("url", info.url))) 
                end
                for repo in info.repos 
                    push!(fetchers, Fetcher(GIT_FETCHER, Dict("url" => repo, "rev" => info.tree_hash)))
                end
                put!(jobs, (info, fetchers)) 
            end
        end

        for i=1:ntasks
            @async begin
                for (info, fetchers) in jobs 
                    selected = nothing
                    for fetcher in fetchers 
                        try
                            fetcher.args["sha256"] = fetch_sha256(fetcher) 
                            selected = fetcher
                            break
                        catch e
                            @error sprint(showerror, e)
                            continue
                        end
                    end
                    put!(results, (;info, fetcher=selected))
                end
            end
        end

        bar = MiniProgressBar(; indent=2, header = "Progress", color = Base.info_color(),
                                percentage=false, always_reprint=true, max = length(infos))
        try
            start_progress(stdout, bar)
            packages = Dict()
            for i=1:length(infos)
                bar.current = i

                r = take!(results)
                if r !== nothing
                    r.info.fetcher = r.fetcher
                end

                print_progress_bottom(stdout)
                show_progress(stdout, bar)
            end

            for info in infos 
                if info.fetcher === nothing
                    error("Package with UUID '$(info.uuid)' has no sources")
                end
            end

            return infos 
        finally
            end_progress(stdout, bar)
            close(jobs)
        end
    end
end

function generate_overrides(infos::Vector{PackageInfo})
    artifacts = Dict{String,Vector


# TODO pass in registries
function generate(package)
    meta = Dict{String,Any}()
    meta["pkgServer"] = isnothing(Pkg.pkg_server()) ? "" : Pkg.pkg_server()

    Pkg.Operations.with_temp_env(package) do
        ctx = Context()
        infos = load_infos(Context())
        load_fetchers!(ctx, infos) 
    end
end

end

sources = M.generate(joinpath(@__DIR__, "../testenv"))

