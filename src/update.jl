function update(path::AbstractString=pwd(); config::AbstractDict=Dict())
    if get(config, "recursive", false)
        if has_project(path)
            _update(path, config)
        end

        for (root, dirs, files) in walkdir(path)
            for dir in dirs
                path = joinpath(root, dir)
                if has_project(path)
                    _update(path, config)
                end
            end
        end
    else
        _update(path, config)
    end
    return nothing
end

function _update(path, config)
    script_file = joinpath(path, "update.jl")
    @info "Updating package at '$path'."
    if isfile(script_file)
        @info "Found update script. Not updating NixManifest.toml."
        run_julia_script(joinpath(path, "update.jl"))
    else
        update_package(path; config)
    end
    return nothing
end

function update_package(package_path::AbstractString=pwd(); config::AbstractDict=Dict())
    @info "Updating NixManifest.toml"
    validate_config(config)

    package = read_package(package_path)
    validate(package)

    if haskey(config, "names")
        names = config["names"] 
        for name in config["names"] 
            if !haskey(package.project.sources, name) 
                nixsourcerer_error("Key $name missing from $(package.project_file)")
            end
        end
    else
        names = keys(package.project.sources)
    end

    workers = length(names) == 1 ? 1 : get(config, "workers", 1)::Integer
    @assert workers > 0

    if workers == 1
        foreach(name -> update!(package, name), names)
    else
        asyncmap(name -> update!(package, name), collect(names); workers)
    end

    @info "Done!"
    return write_package(package)
end

function update!(package::Package, name::AbstractString)
    @info "Updating '$name'"
    try
        project_source = package.project.sources[name]
        manifest_source = HANDLERS[project_source["type"]](name, project_source)

        merge_recursively!(manifest_source.meta, get(project_source, "meta", Dict()))

        package.manifest.sources[name] = manifest_source
    catch
        nixsourcerer_error("Could not update source $name")
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
     
