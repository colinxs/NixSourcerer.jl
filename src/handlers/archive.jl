const ARCHIVE_SCHEMA = CompositeSchema(
    SimpleSchema("url", String, true),
    SimpleSchema("builtin", Bool, false),
)

function archive_handler(name::AbstractString, source::AbstractDict)
    fetcher = get(source, "builtin", false) ? "builtins.fetchTarball" : "pkgs.fetchzip"
    fetcher_args = subset(source, "url")
    fetcher_args["sha256"] = get_sha256(fetcher, fetcher_args)
    return Source(;pname = name, version = fetcher_args["sha256"], fetcher, fetcher_args)
end


