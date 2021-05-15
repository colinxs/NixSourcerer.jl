function update(path::AbstractString=pwd(); config::AbstractDict=Dict())
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
        # shuffle!(julia_updates)
        # shuffle!(normal_updates)

        @info "Updating the following paths:"
        for path in normal_updates
            print(
                "F=$(Int(has_flake(path))) ",
                "M=$(Int(has_project(path))) ",
                "J=$(Int(has_julia_project(path))) ",
                "S=$(Int(has_update_script(path))) |",
            )
            println(relpath(path, pwd()))
        end
        for path in julia_updates
            has_script = has_update_script(path)
            print("F=0 M=0 J=$(Int(!has_script && has_julia_project(path))) S=$(Int(has_script)) |")
            println(relpath(path, pwd()))
        end

        workers = length(normal_updates) == 1 ? 1 : get(config, "workers", 1)::Integer
        @sync begin
            @async begin
                if workers == 1
                    foreach(path -> _update(path, config), normal_updates)
                else
                    asyncmap(path -> _update(path, config), normal_updates; ntasks=workers)
                end
            end
            begin
                # Have to do Julia script updates sequentially as
                # depot is not safe to async Pkg operations
                for path in julia_updates
                    @async _update(path, config)
                end
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
    if has_update_script(path)
        run_julia_script(get_update_script(path))
        @info "Updated using script at $path. Skipped updating NixManifest.toml/flake.nix/Manifest.toml."
    else
        if has_flake(path)
            update_flake(path)
            @info "Updated flake at $path"
        end
        if has_julia_project(path)
            update_julia_project(path)
            @info "Updated Julia project at $path"
        end
        if has_project(path)
            update_package(path; config)
            @info "Updated NixManifest.toml at $path"
        end
    end

    return nothing
end

function update_flake(path)
    @info path
    flake = get_flake(path)
    cmd = `nix-shell -p nixUnstable --command 'nix flake update'`
    run(pipeline(setenv(cmd; dir=path), stderr=devnull))
    return nothing
end

function update_julia_project(path)
    cmd = `julia --project=$(path) --startup-file=no --history-file=no -e 'using Pkg; Pkg.update()'`
    run(setenv(cmd; dir=path))
    return nothing
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
    try
        project_spec = package.project.specs[name]
        manifest_source = HANDLERS[project_spec["type"]](name, project_spec)

        merge_recursively!(manifest_source.meta, get(project_spec, "meta", Dict()))

        package.manifest.sources[name] = manifest_source
    catch e
        # nixsourcerer_error("Could not update source $name")
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
