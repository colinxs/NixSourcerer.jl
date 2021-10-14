update(path::AbstractString, args...; kwargs...) = update([ path ], args...; kwargs...)

function update(paths::Vector{<:AbstractString}=[pwd()]; config::AbstractDict=Dict())
    config = parse_config(config)

    setup(config)

    if config["verbose"]
        ENV["JULIA_DEBUG"] = string(@__MODULE__)
    end

    allpaths = String[]
    if config["recursive"]
        for path in paths
            should_update(path) && push!(allpaths, path)
            if isdir(path)
                for (root, dirs, files) in walkdir(path)
                    for dir in dirs
                        path = joinpath(root, dir)
                        should_update(path) && push!(allpaths, path)
                    end
                end
            end
        end
    else
        append!(allpaths, paths)
    end

    # TODO makes debugging failures difficult
    # Try to catch dependencies between updates
    # shuffle!(allpaths)

    print_path = function (path)
        path = cleanpath(path)
        s = !config["ignore-script"] && has_update_script(path)
        j = !s && has_julia_project(path)
        f = !j && !s && has_flake(path)
        n = !j && !s && has_project(path)
        s, j, f, n = map(x -> x ? "+" : "-", (s, j, f, n))
        str = @sprintf "%-4sS%-3sJ%-3sF%-3sN%-3s%-10s" "" s j f n ""
        printstyled(str; color=:magenta)
        return println(path == "." ? ". (cwd)" : path)
    end

    printstyled("Updating the following paths:\n"; color=:blue, bold=true)
    printstyled("S = Update (S)cript | "; color=:blue, bold=true)
    printstyled("J = (J)ulia Project | "; color=:blue, bold=true)
    printstyled("F = (F)lake | "; color=:blue, bold=true)
    printstyled("N = (NVecVe)ix Project\n\n"; color=:blue, bold=true)

    foreach(print_path, allpaths)
    println()

    # DEBUG
    # Threads.@threads for path in allpaths 
    #     _update(path, config)
    # end
    # return

    # Since we're updating N paths with M packages each try not to use N*M workers
    workers = min(length(allpaths), config["workers"])
    workers = config["workers"] = round(Int, sqrt(workers), RoundUp)

    if workers == 1
        foreach(path -> _update(path, config), allpaths)
    else
        asyncmap(path -> _update(path, config), allpaths; ntasks=workers)
    end

    println()
    printstyled("Done! Congrats on updating $(length(allpaths)) package(s):\n"; color=:blue, bold=true)

    return nothing
end

function _update(path, config)
    dryrun = config["dry-run"]

    printstyled("Updating $(cleanpath(path))\n"; color=:yellow, bold=true)
    if has_update_script(path)
        dryrun || run_julia_script(path)
        printstyled(
            "Updated using script at $(cleanpath(get_update_script(path))). Skipped NixManifest.toml/$(FLAKE_FILENAME)/Manifest.toml.\n";
            color=:green,
            bold=true,
        )
        return path
    else
        if has_project(path)
            dryrun || update_package(path; config)
            printstyled("Updated NixManifest.toml at $(cleanpath(get_project(path)))\n"; color=:green, bold=true)
        end
        if has_flake(path)
            dryrun || update_flake(path)
            printstyled("Updated flake at $(cleanpath(get_flake(path)))\n"; color=:green, bold=true)
        end
        if has_julia_project(path)
            dryrun || update_julia_project(path)
            printstyled("Updated Julia project at $(cleanpath(get_julia_project(path)))\n"; color=:green, bold=true)
        end
        return path
    end

    return nothing
end

function setup(config)
    # We don't want overlays or anything else as it breaks nix-prefetch
    nixpkgs = strip(run_suppress(`nix eval '(<nixpkgs>)'`; out=true))
    isdir(nixpkgs) || nixsourcerer_error("Could not locate <nixpkgs> in NIX_PATH")
    ENV["NIX_PATH"] = "nixpkgs=$(nixpkgs)"

    # We only want to update the registry once per session
    if !config["no-update-julia-registries"]
        run_suppress(`julia --startup-file=no --history-file=no -e 'using Pkg; Pkg.Registry.update()'`)
        # Pkg.Registry.update()
    end

    return nothing
end

should_update(path) = has_update_script(path) || has_project(path) || has_flake(path) || has_julia_project(path)

has_file(file_or_dir, filename) = isfile(get_file(file_or_dir, filename))
function get_file(file_or_dir, filename)
    file = isfile(file_or_dir) && basename(file_or_dir) == filename ? file_or_dir : joinpath(file_or_dir, filename)
    return abspath(file)
end

get_update_script(path) = get_file(path, UPDATE_SCRIPT_FILENAME)
has_update_script(path) = has_file(path, UPDATE_SCRIPT_FILENAME)

get_flake(path) = get_file(path, FLAKE_FILENAME)
has_flake(path) = has_file(path, FLAKE_FILENAME)

get_julia_project(path) = get_file(path, JULIA_PROJECT_FILENAME)
has_julia_project(path) = has_file(path, JULIA_PROJECT_FILENAME)

get_project(path) = get_file(path, PROJECT_FILENAME)
has_project(path) = has_file(path, PROJECT_FILENAME)

get_manifest(path) =
    get_file(isfile(path) && basename(path) == PROJECT_FILENAME ? dirname(path) : path, MANIFEST_FILENAME)
has_manifest(path) =
    has_file(isfile(path) && basename(path) == PROJECT_FILENAME ? dirname(path) : path, MANIFEST_FILENAME)

function update_flake(path)
    path = dirname(get_flake(path))
    run_suppress(`nix-shell -p nixUnstable --command "nix flake update $path"`)
    return path
end

function update_julia_project(path)
    path = get_julia_project(path)
    run_suppress(`julia --project=$path --startup-file=no --history-file=no -e 'using Pkg; Pkg.update()'`)
    return path
end

function update_package(path::AbstractString=pwd(); config::AbstractDict=Dict())
    config = parse_config(config)

    if config["verbose"]
        ENV["JULIA_DEBUG"] = string(@__MODULE__)
    end

    validate_config(config)

    package = read_package(path)
    validate(package)

    if haskey(config, "names")
        names = config["names"]
        for name in config["names"]
            if !haskey(package.project.specs, name)
                nixsourcerer_error("Key $name missing from $(package.project_file)")
            end
        end
    else
        names = keys(package.project.specs)
    end

    workers = min(length(names), config["workers"])

    if workers == 1
        foreach(name -> update!(package, name), names)
    else
        asyncmap(name -> update!(package, name), collect(names); ntasks=workers)
    end

    return write_package(package)
end

function update!(package::Package, name::AbstractString)
    path = cleanpath(dirname(package.project_file))
    try
        project_spec = package.project.specs[name]
        manifest_source = HANDLERS[project_spec["type"]](name, project_spec)

        merge_recursively!(manifest_source.meta, get(project_spec, "meta", Dict()))

        package.manifest.sources[name] = manifest_source

        printstyled("    Updated package $name from $path\n"; color=:green)
    catch e
        nixsourcerer_error("Could not update source $name from $path")
        rethrow()
    end
    return package
end
