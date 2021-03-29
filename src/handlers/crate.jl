const CRATE_SCHEMA = [
    SimpleSchema("pname", String, true)
    SimpleSchema("version", String, true)
    SimpleSchema("builtin", Bool, false)
]

const CRATES_IO_BASE_URL="https://crates.io/api/v1/crates"

function crate_handler(name::AbstractString, spec::AbstractDict)
    verify(CRATE_SCHEMA, name, spec) 

    pname = spec["pname"]
    version = parse_crate_version(pname, spec["version"])

    new_spec = subset(spec, "builtin")
    new_spec["url"] = crate_tarball_url(pname, version) 

    fetcher, fetcherargs, meta = archive_handler(name, new_spec)
    meta = merge(meta, Dict("version" => version))

    return fetcher, fetcherargs, meta
end

function parse_crate_version(pname::AbstractString, version::AbstractString)
    if version == "stable"
        metadata = crate_metadata(pname)
        version = metadata["crate"]["max_stable_version"]
    elseif version == "latest"
        metadata = crate_metadata(pname)
        version = metadata["crate"]["max_version"]
    end
    return version
end

function crate_metadata(pname::AbstractString)
    return JSON.parse(String(HTTP.get("$(CRATES_IO_BASE_URL)/$(pname)").body))
end

function crate_tarball_url(pname::AbstractString, version::AbstractString)
    return "$(CRATES_IO_BASE_URL)/$(pname)/$(version)/download#crate.tar.gz"
end
