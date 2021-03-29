const FILE_SCHEMA = [
    SimpleSchema("url", String, true)
    SimpleSchema("builtin", Bool, false)
]

function file_handler(name::AbstractString, spec::AbstractDict)
    verify(FILE_SCHEMA, name, spec)

    builtin = get(spec, "builtin", false)

    fetcher = builtin ? "builtins.fetchurl" : "pkgs.fetchurl"
    fetcherargs = subset(spec, "url")
    meta = Dict()

    fetcherargs["sha256"] = get_sha256(fetcher, fetcherargs)
    
    return fetcher, fetcherargs, meta
end
