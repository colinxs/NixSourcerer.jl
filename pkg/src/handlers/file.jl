const FILE_SCHEMA = SchemaSet(
    SimpleSchema("url", String, true), SimpleSchema("builtin", Bool, false)
)

function file_handler(name::AbstractString, spec::AbstractDict)
    builtin = get(spec, "builtin", true)

    fetcher_name = builtin ? "builtins.fetchurl" : "pkgs.fetchurl"
    fetcher_args = subset(spec, "url")
    fetcher_args["sha256"] = sha256 = get_sha256(fetcher_name, fetcher_args)
    return Source(; pname=name, version=sha256, fetcher_name, fetcher_args)
end
