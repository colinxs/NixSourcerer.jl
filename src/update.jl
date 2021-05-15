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
            path = relpath(path, pwd())
            path = path == "." ? ". (cwd)" : path
            j = has_julia_project(path)
            s = has_update_script(path)
            f = !j && !s && has_flake(path)
            m = !j && !s && has_project(path)
            j, s, f, m = map(x -> x ? "+" : "-", (j, s, f, m)) 
            str = @sprintf "%-4sJ%-3sS%-3sF%-3sM%-3s%-10s" "" j s f m ""
            printstyled(str, color=:magenta)
            println(path)
        end
        printstyled("Updating the following paths:\n", color=Base.info_color(), bold=true)
        for path in normal_updates
            print_path(path)
        end
        for path in julia_updates
            print_path(path)
        end
        println()

        # DEBUG
        for path in normal_updates
            _update(path, config)
        end
        for path in julia_updates
            _update(path, config)
        end
        return

        workers = length(normal_updates) == 1 ? 1 : get(config, "workers", 1)::Integer
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

    else
        _update(path, config)
    end
    return nothing
end

should_update(path) = has_update_script(path) || has_project(path) || has_flake(path)
get_update_script(path) = joinpath(path, "update.jl")
has_update_script(path) = isfile(get_update_script(path))
get_flake(path) = joinpath(path, "flake.nix")
has_flake(path) = isfile(get_flake(path))
has_julia_project(path) = Pkg.Types.projectfile_path(path; strict=true) !== nothing

function _update(path, config)
    rpath = relpath(path, pwd())
    printstyled("Updating $rpath\n", color=:yellow, bold=true)
    if has_update_script(path)
        run_julia_script(get_update_script(path))
        println("Updated using script at $rpath. Skipped updating NixManifest.toml/flake.nix/Manifest.toml.")
    else
        if has_flake(path)
            update_flake(path)
            printstyled("Updated flake at $rpath\n", color=:green, bold=true)
        end
        if has_julia_project(path)
            update_julia_project(path)
            printstyled("Updated Julia project at $rpath\n", color=:green, bold=true)
        end
        if has_project(path)
            update_package(path; config)
            printstyled("Updated NixManifest.toml at $rpath\n", color=:green, bold=true)
        end
    end

    return nothing
end

function update_flake(path)
    flake = get_flake(path)
    cmd = `nix-shell -p nixUnstable --command 'nix flake update'`
    run(pipeline(setenv(cmd; dir=path), stderr=devnull))
    return path
end

function update_julia_project(path)
    cmd = `julia --project=$(path) --startup-file=no --history-file=no -e 'using Pkg; Pkg.update()'`
    run(pipeline(setenv(cmd, dir=path), stderr=devnull))
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
    rpath = relpath(dirname(package.project_file), pwd())
    try
        project_spec = package.project.specs[name]
        manifest_source = HANDLERS[project_spec["type"]](name, project_spec)

        merge_recursively!(manifest_source.meta, get(project_spec, "meta", Dict()))

        package.manifest.sources[name] = manifest_source

        printstyled("    Updated package $name from $rpath\n", color=:green)
    catch e
        nixsourcerer_error("Could not update source $name from $rpath")
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
