const ARCHIVE_SCHEMA = SchemaSet(
    SimpleSchema("url", String, true), SimpleSchema("builtin", Bool, false)
)

function archive_handler(name::AbstractString, spec::AbstractDict)
    # NOTE builtin fetcher appears to be faster
    builtin = get(spec, "builtin", true)

    uri = URI(spec["url"])
    fetcher_name = builtin ? "builtins.fetchTarball" : "pkgs.fetchzip"
    fetcher_args = Dict{Symbol,Any}()
    fetcher_args[:url] = spec["url"]
    fetcher_args[:name] = sanitize_name(get(spec, "name", "$(uri.host)=$(splitpath(uri.path)[end])"))
    fetcher_args[:sha256] = get_sha256(fetcher_name, fetcher_args)

    return Source(; pname=name, version=fetcher_args[:sha256], fetcher_name, fetcher_args)
end
