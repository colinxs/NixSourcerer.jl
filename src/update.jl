function update(path::AbstractString=pwd(); config::AbstractDict=Dict())
    if get(config, "recursive", false)
        for (root, dirs, files) in walkdir(path)
            _update(path, config)
            for dir in dirs
                path = joinpath(root, dir)
                if has_project(path)
                    @info path
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
    if isfile(script_file)
        @info "Found $script_file. Skipping package update."
        run_julia_script(joinpath(path, "update.jl"))
    else
        @info "Updating package at $path."
        update_package(path; config)
        @info "Done!"
    end
    return nothing
end

function update_package(package_path::AbstractString=pwd(); config::AbstractDict=Dict())
    package = read_package(package_path)
    validate(package)

    names = keys(package.project.sources)
    ntasks = get(config, "ntasks", 1)::Integer
    @assert ntasks > 0
    if ntasks == 1
        foreach(name -> update!(package, name), names)
    else
        asyncmap(name -> update!(package, name), collect(names); ntasks)
    end

    return write_package(package)
end

function update!(package::Package, name::AbstractString)
    @info "Updating $name"
    project_source = package.project.sources[name]
    manifest_source = HANDLERS[project_source["type"]](name, project_source)

    merge_recursively!(manifest_source.meta, get(project_source, "meta", Dict()))

    package.manifest.sources[name] = manifest_source
    return package
end
