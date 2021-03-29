const ARCHIVE_SCHEMA = [
    SimpleSchema("url", String, true)
    SimpleSchema("builtin", Bool, false)
]

function archive_handler(name::AbstractString, spec::AbstractDict)
    verify(ARCHIVE_SCHEMA, name, spec)

    builtin = get(spec, "builtin", false)

    fetcher = builtin ? "builtins.fetchTarball" : "pkgs.fetchzip"
    fetcherargs = subset(spec, "url")
    meta = Dict()

    fetcherargs["sha256"] = get_sha256(fetcher, fetcherargs)
    
    return fetcher, fetcherargs, meta
end


