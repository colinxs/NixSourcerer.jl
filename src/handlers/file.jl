const FILE_SCHEMA = SchemaSet(
    SimpleSchema("url", String, true), SimpleSchema("builtin", Bool, false)
)

function file_handler(name::AbstractString, spec::AbstractDict)
    builtin = get(spec, "builtin", false)

    fetcher_args = Dict{Symbol,Any}()
    fetcher_args[:url] = spec["url"]
    # fetcher_args[:name] = sanitize_name(get(spec, "name", url_name(spec["url"])))
    fetcher_name = builtin ? "builtins.fetchurl" : "pkgs.fetchurl"
    fetcher_args[:sha256] = sha256 = get_sha256(fetcher_name, fetcher_args)

    return Source(; pname=name, version=sha256, fetcher_name, fetcher_args)
end
