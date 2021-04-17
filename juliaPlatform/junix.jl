using Pkg
using Pkg: pkg_server
using Pkg.Types: PackageInfo, Context
using Pkg.MiniProgressBars
using TOML
using Base: UUID
using NixSourcerer
using NixSourcerer: Source

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

function get_repos_from_registry(registries::Vector{RegistrySpec}, uuid::UUID)
    repos = Set{String}()
    uuidstr = string(uuid)
    for registry in registries
        known = TOML.parsefile(joinpath(registry.path, "Registry.toml"))["packages"]
        if haskey(known, uuidstr)
            info = TOML.parsefile(joinpath(registry.path, known[uuidstr]["path"], "Package.toml"))
            push!(repos, info["repo"])
        end
    end
    return sort!(collect(repos))
end

function load_package_urls(ctx::Context)
    alldeps = Pkg.dependencies(ctx)
    deps = Dict{UUID,PackageInfo}()
    archives = Dict{UUID,Vector{String}}()
    repos = Dict{UUID,Vector{String}}()
    registries = Pkg.Types.collect_registries()
    for (uuid, pkg) in alldeps
        repos[uuid] = String[]
        archives[uuid] = String[]

        # TODO version from Project.toml?
        if Pkg.Types.is_stdlib(uuid, VERSION)
            continue
        elseif pkg.is_tracking_registry
            push!(archives[uuid], get_pkg_url(uuid, pkg.tree_hash))
            for repo in get_repos_from_registry(registries, uuid)
                push!(repos[uuid], repo) 
                url = get_archive_url_for_version(repo, pkg.tree_hash)
                if url !== nothing
                    push!(archives[uuid], url)
                end
            end
        elseif pkg.is_tracking_repo
            push!(repos[uuid], pkg.git_source)
        elseif pkg.is_tracking_path
            error("Package $(pkg.name) ($(uuid)) is tracking a path")
        else
            error("Package $(pkg.name) ($(uuid)) is has no known source") 
        end

        deps[uuid] = alldeps[uuid]
    end
    return (; archives, repos, deps)
end

function get_nix_source(fetcher, args)
    cmd = pipeline(`nix-prefetch $fetcher --hash-algo sha256 --output nix $args`, stderr=devnull)
    return strip(read(cmd, String))
end

function get_source_path(ctx::Context, pkg::PackageInfo)
    spec = Pkg.Types.PackageSpec(name=pkg.name, uuid=UUID(pkg.uuid), tree_hash = Base.SHA1(pkg.tree_hash))
    Pkg.Operations.source_path(ctx, spec)
end

gen_name(pkg::PackageInfo) = "$(pkg.name)-$(pkg.version)"

function generate_sources(archives, repos, deps_to_install::Dict{UUID,PackageInfo}; ntasks = 5)
    Base.Experimental.@sync begin
    # @sync begin
        jobs = Channel(ntasks)
        results = Channel(ntasks)

        @async begin
            for (uuid, pkg) in deps_to_install
                put!(jobs, (uuid, pkg))
            end
        end

        for i=1:ntasks
            @async begin
                for (uuid, pkg) in jobs
                    src = nothing

                    for url in archives[uuid]
                        try
                            # NOTE nixpkgs.fetchzip doesn't know how to handle archives
                            # without a suffix like those from pkg server
                            # src = get_nix_source("builtins.fetchTarball", ["--url", url])
                            # src = get_nix_source("builtins.fetchTarball", ["--url", url])
                            spec = Dict("url" => url, "builtin" => true)
                            src = NixSourcerer.file_handler(gen_name(pkg), spec)
                            break
                        catch e
                            @error sprint(showerror, e)
                            continue
                        end
                    end

                    if src === nothing
                        for repo in repos[uuid]
                            try
                                # src = get_nix_source("fetchgit", ["--url", repo, "--rev", pkg.tree_hash])
                                spec = Dict("url" => repo, "rev" => pkg.tree_hash, "builtin" => false)
                                src = NixSourcerer.git_handler(gen_name(pkg), spec)
                                break
                            catch e
                                @error e
                                continue
                            end
                        end
                    end

                    if !(src === nothing)
                        src.meta["name"] = pkg.name
                        src.meta["version"] = pkg.version
                        src.meta["tree_hash"] = pkg.tree_hash
                    end

                    put!(results, (uuid, src))
                end
            end
        end

        bar = MiniProgressBar(; indent=2, header = "Progress", color = Base.info_color(),
                                percentage=false, always_reprint=true, max = length(deps_to_install))
        try
            start_progress(stdout, bar)
            manifest = NixSourcerer.Manifest()
            for i=1:length(deps_to_install)
                bar.current = i
                uuid, src = take!(results)
                if src === nothing 
                    error("No sources for UUID '$(uuid)'")
                else
                    print_progress_bottom(stdout)
                    show_progress(stdout, bar)
                end
                manifest.sources[string(uuid)] = src
            end

            return manifest 
        finally
            end_progress(stdout, bar)
            close(jobs)
        end
    end

end

function generate_nix_expression(sources::Dict{UUID,})
    str = sprint() do io
        print(io, "{\n")
        for (uuid, src) in sources
            print(io, '"', uuid, '"')
            print(io, " = ")
            print(io, src)
            print(io, ";\n")
        end
        print(io, "}")
    end
    return str
end

function generate(package)
    archives, repos, deps = Pkg.Operations.with_temp_env(package) do
        load_package_urls(Context())
    end

    manifest = generate_sources(archives, repos, deps)

    # expr = generate_nix_expression(sources)

    # write(joinpath(@__DIR__, "./Example.nix"), expr)
    NixSourcerer.write_manifest(manifest, joinpath(@__DIR__, "./Example.nix"))

    return manifest
end
manifest = generate(joinpath(@__DIR__, "../testenv"))

