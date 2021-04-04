const FILE_SCHEMA = CompositeSchema(
    SimpleSchema("url", String, true),
    SimpleSchema("builtin", Bool, false),
)

function file_handler(name::AbstractString, source::AbstractDict)
    builtin = get(source, "builtin", false)

    fetcher = builtin ? "builtins.fetchurl" : "pkgs.fetchurl"
    fetcher_args = subset(source, "url")
    fetcher_args["sha256"] = get_sha256(fetcher, fetcher_args)
    
    return Source(;pname = name, version = fetcher_args["sha256"], fetcher, fetcher_args)
end
