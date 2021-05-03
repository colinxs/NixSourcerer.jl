# TODO move to NixSourcerer?
function get_archive_url_for_version(url::String, ref)
    if (m = match(r"https://github.com/(.*?)/(.*?).git", url)) !== nothing
        return "https://api.github.com/repos/$(m.captures[1])/$(m.captures[2])/tarball/$(ref)"
    end
    return nothing
end

function get_pkg_url(uuid::UUID, tree_hash::String)
    if (server = pkg_server()) !== nothing
        return "$server/package/$(uuid)/$(tree_hash)"
    end
end

function get_source_path(ctx::Context, name::String, uuid::UUID, tree_hash::SHA1) 
    spec = Pkg.Types.PackageSpec(; name, uuid, tree_hash)
    path = Pkg.Operations.source_path(ctx, spec)
    for depot in DEPOT_PATH
        if startswith(normpath(path), normpath(depot))
            return depot, relpath(normpath(path), normpath(depot))
        end
    end
    return nothing
end

function convert_sha256(data::String, base::Symbol)
    flag = if base === :base16
        "--to-base16"
    elseif base === :base32
        "--to-base32"
    else
        error("Unknown base $base")
    end
    read(`nix-hash --type sha256 $flag $data`, String)
end

function fetch_sha256(fetcher::Fetcher)
    args = copy(fetcher.args)
    parsed = ["--hash-algo", "sha256", "--output", "raw"]
    if haskey(args, "sha256")
         push!(parsed, "--no-compute-hash")
         args["hash"] = args["sha256"]
         delete!(args, "sha256")
    end
    for (k, v) in args
        push!(parsed, "--$(k)")
        if v !== nothing
            push!(parsed, string(v))
        end
    end
    cmd = `nix-prefetch $(fetcher.name) $(parsed)`
    return strip(read(pipeline(cmd, stderr=devnull), String))
end

function isvalid_url(url::String)
    try
        HTTP.head(url, status_exception = true)
        return true
    catch
        return false
    end
end



