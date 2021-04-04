function update(package_path)
    package = read_package(package_path)
    validate(package)

    for (name, source) in package.project.sources
        @info "Updating source $name"
        package.manifest.sources[name] = HANDLERS[source["type"]](name, source)
    end

    write_package(package)
    
    @info "Done!"
end

function update_source(name, spec)
    fetcher, fetcherargs, meta = HANDLERS[spec["type"]](name, spec)

    meta["lastChecked"] = round(Integer, time()) 
    meta["original"] = spec

    return fetcher, fetcherargs, meta
end
    
