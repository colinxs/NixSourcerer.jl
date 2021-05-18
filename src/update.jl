function update(path::AbstractString=pwd(); config::AbstractDict=Dict())
    isdir(path) || nixsourcerer_error("Not a directory: $(path)")

    if get(config, "recursive", false)
        julia_updates = String[]
        normal_updates = String[]
        if should_update(path)
            push!(
                if (has_update_script(path) || has_julia_project(path))
                    julia_updates
                else
                    normal_updates
                end,
                path,
            )
        end

        for (root, dirs, files) in walkdir(path)
            for dir in dirs
                path = joinpath(root, dir)
                if should_update(path)
                    push!(
                        if (has_update_script(path) || has_julia_project(path))
                            julia_updates
                        else
                            normal_updates
                        end,
                        path,
                    )
                end
            end
        end

        # Try to catch dependencies between updates
        shuffle!(julia_updates)
        shuffle!(normal_updates)

        print_path = function (path)
            path = cleanpath(path) 
            path = path == "." ? ". (cwd)" : path
            j = has_julia_project(path)
            s = has_update_script(path)
            f = !j && !s && has_flake(path)
            n = !j && !s && has_project(path)
            j, s, f, n = map(x -> x ? "+" : "-", (j, s, f, n))
            str = @sprintf "%-4sJ%-3sS%-3sF%-3sN%-3s%-10s" "" j s f n ""
            printstyled(str; color=:magenta)
            return println(path)
        end

        printstyled("Updating the following paths:\n"; color=:blue, bold=true)
        printstyled("J = (J)ulia Project | "; color=:blue, bold=true)
        printstyled("S = Update (S)cript | "; color=:blue, bold=true)
        printstyled("F = (F)lake | "; color=:blue, bold=true)
        printstyled("N = (N)ix Project\n\n"; color=:blue, bold=true)

        foreach(print_path, normal_updates)
        foreach(print_path, julia_updates)
        println()

        # DEBUG
        # for path in normal_updates
        #     _update(path, config)
        # end
        # for path in julia_updates
        #     _update(path, config)
        # end
        # return

        # Since we're updating N paths with M packages each try not to use N*M workers
        workers = length(normal_updates) == 1 ? 1 : get(config, "workers", 1)::Integer
        @assert workers >= 1
        workers = round(Int, sqrt(workers), RoundUp)

        @sync begin
            @async begin
                if workers == 1
                    foreach(path -> _update(path, config), normal_updates)
                else
                    asyncmap(path -> _update(path, config), normal_updates; ntasks=workers)
                end
            end
            # TODO seems to be fine after disabling registry updates. Revisit.
            # Have to do Julia script updates sequentially as
            # depot is not safe to async Pkg operations
            for path in julia_updates
                @async _update(path, config)
            end
        end
        
        len = length(normal_updates) + length(julia_updates)
    else
        _update(path, config)
        len = 1
    end

    println()
    printstyled("Done! Congrats on updating $(len) package(s):\n"; color=:blue, bold=true)

    return nothing
end

should_update(path) = has_update_script(path) || has_project(path) || has_flake(path)
get_update_script(path) = joinpath(path, "update.jl")
has_update_script(path) = isfile(get_update_script(path))
get_flake(path) = joinpath(path, "flake.nix")
has_flake(path) = isfile(get_flake(path))
has_julia_project(path) = Pkg.Types.projectfile_path(path; strict=true) !== nothing

function _update(path, config)
    cpath = cleanpath(path) 
    printstyled("Updating $cpath\n"; color=:yellow, bold=true)
    if has_update_script(path)
        run_julia_script(get_update_script(path))
        printstyled(
            "Updated using script at $cpath. Skipped updating NixManifest.toml/flake.nix/Manifest.toml.\n";
            color=:green,
            bold=true,
        )
    else
        if has_flake(path)
            update_flake(path)
            printstyled("Updated flake at $cpath\n"; color=:green, bold=true)
        end
        if has_julia_project(path)
            update_julia_project(path)
            printstyled("Updated Julia project at $cpath\n"; color=:green, bold=true)
        end
        if has_project(path)
            update_package(path; config)
            printstyled("Updated NixManifest.toml at $cpath\n"; color=:green, bold=true)
        end
    end

    return nothing
end

function update_flake(path)
    flake = get_flake(path)
    cmd = `nix-shell -p nixUnstable --command 'nix flake update'`
    run(pipeline(setenv(cmd; dir=path); stderr=devnull))
    return path
end

function update_julia_project(path)
    cmd = `julia --project=$(path) --startup-file=no --history-file=no -e 'using Pkg; Pkg.update()'`
    run(pipeline(setenv(cmd; dir=path); stderr=devnull))
    return path
end

function update_package(package_path::AbstractString=pwd(); config::AbstractDict=Dict())
    validate_config(config)

    package = read_package(package_path)
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

    workers = length(names) == 1 ? 1 : get(config, "workers", 1)::Integer
    @assert workers > 0

    if workers == 1
        foreach(name -> update!(package, name), names)
    else
        asyncmap(name -> update!(package, name), collect(names); ntasks=workers)
    end

    return write_package(package)
end

function update!(package::Package, name::AbstractString)
    cpath = cleanpath(dirname(package.project_file))
    try
        project_spec = package.project.specs[name]
        manifest_source = HANDLERS[project_spec["type"]](name, project_spec)

        merge_recursively!(manifest_source.meta, get(project_spec, "meta", Dict()))

        package.manifest.sources[name] = manifest_source

        printstyled("    Updated package $name from $cpath\n"; color=:green)
    catch e
        nixsourcerer_error("Could not update source $name from $cpath")
        rethrow()
    end
    return package
end

function validate_config(config::AbstractDict)
    if get(config, "recursive", false) && haskey(config, "names")
        nixsourcerer_error("Cannot specify 'recursive' and 'names' at the same time")
    end
    get(config, "workers", 1) > 0 || nixsourcerer_error("'workers' must be > 0)")
    return nothing
end
