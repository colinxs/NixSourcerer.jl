function get_sha256(expr::String, args::Vector{String}=["--hash-algo", "sha256"])
    expr = """
           with (import <nixpkgs> { });
           $expr
           """
    cmd = `nix-prefetch $expr --output raw $args`
    return check_sha256(strip(run_suppress(cmd; out=true)))
end

function get_sha256(fetcher_name::String, fetcher_args::Dict{Symbol,<:Any})
    if startswith(fetcher_name, "builtins")
        # builtins don't produce a derivation and so can't be fetched as expressions
        args = [fetcher_name, "--output", "raw"]
        if fetcher_name in NO_HASH_FETCHERS
            push!(args, "--no-compute-hash")
        end
        for (k, v) in fetcher_args
            push!(args, "--$(k)")
            push!(args, string(v))
        end
        return check_sha256(strip(run_suppress(`nix-prefetch $args`; out=true)))
    else
        expr = "$fetcher_name $(Nix.print(fetcher_args))"
        return get_sha256(expr)
    end
end

function get_cargosha256(pkg)
    # Not sure what exactly to override here..
    # See: https://github.com/Mic92/nix-update/issues/55
    expr = "{ sha256 }: $(pkg).cargoDeps.overrideAttrs (_: { inherit sha256; cargoSha256 = sha256; outputHash = sha256; })"
    return get_sha256(expr)
end

function get_yarnsha256(pkg)
    expr = "{ sha256 }: $(pkg).yarnDeps.overrideAttrs (_: { inherit sha256; yarnSha256 = sha256; outputHash = sha256; })"
    return get_sha256(expr)
end

function check_sha256(str)
    # From nix/src/libutil/hash.cc
    if match(r"^[0123456789abcdfghijklmnpqrsvwxyz]{52}$", str) === nothing
        error("Invalid Base-32 SHA256: $str")
    end
    return str 
end

# TODO may actually want to use <nixpkgs>
# Consider doing only if nixpkgs not on NIX_PATH
function build_source(fetcher_name, fetcher_args)
    expr = "(with $(nixpkgs()); ($fetcher_name $(Nix.print(fetcher_args))).outPath)"
    return run_suppress(`nix eval $expr`)
end

function nixpkgs(args::AbstractDict=Dict())
    return "(import (import $(DEFAULT_NIX)).inputs.nixpkgs $(Nix.print(args)))"
end

function merge_recursively!(a::AbstractDict, b::AbstractDict)
    for (k, v) in b
        if v isa AbstractDict
            merge_recursively!(a[k], v)
        else
            a[k] = v
        end
    end
    return a
end

git_short_rev(rev) = SubString(rev, 1:7)

# Taken from https://github.com/NixOS/nix/blob/bd6cf25952a42afabea822141798566e0f0583b3/src/libexpr/lexer.l#L91
function sanitize_name(name)
    valid = r"^[a-zA-Z\_][a-zA-Z0-9\_\'\-]*$"
    allowed = r"[^a-zA-Z0-9\_\'\-]"
    name = replace(name, allowed => '_')
    while match(valid, name) == nothing
        name = name[2:end]
    end
    return name
end

quote_string(s) = "'$s'"

function run_suppress(cmd; out=false)
    if get(ENV, "JULIA_DEBUG", nothing) == string(@__MODULE__)
        return out ? read(cmd, String) : (run(cmd); nothing)
    end

    stdout = IOBuffer()
    cmd = pipeline(cmd; stdout)

    pty_slave, pty_master = open_fake_pty()
    p = run(cmd, pty_slave, pty_slave, pty_slave; wait=false)
    wait(p)
    Base.close_stdio(pty_slave)

    stderr = IOBuffer()
    try
        write(stderr, read(pty_master), '\n')
    catch e
        close(pty_master)
        if !(e isa Base.IOError && e.code == Base.UV_EIO)
            # ignore EIO on pty_master after pty_slave dies
            rethrow()
        end
    end
    errmsg = String(take!(stderr))

    if p.exitcode > 0
        msg = "Failed to run cmd:\n$(cmd.cmd)\nError:\n\n" * errmsg
        println(msg)
        Base.pipeline_error(p)
    else
        msg = "Ran cmd: $(cmd.cmd)\n" * errmsg
        @debug msg
    end

    return out ? String(take!(stdout)) : nothing
end

function issubpath(path::String, parent::String)
    return startswith(abspath(path), rstrip(abspath(parent), '/'))
end

function cleanpath(path::String)
    cwd = pwd()
    return issubpath(path, cwd) ? joinpath(".", relpath(path, cwd)) : abspath(path)
end

subset(d::AbstractDict, keys...) = Dict{String,Any}(k => d[k] for k in keys if haskey(d, k))

has_nix_shell(path) = isfile(joinpath(path, "shell.nix"))

function url_name(url)
    uri = URI(url)
    return git_short_rev(bytes2hex(sha256("$(uri.host)$(uri.path)")))
end

function parse_config(config)
    p = convert(Dict{String,Any}, copy(config))
    validate_config(p)
    p                  = convert(Dict{String,Any}, copy(config))
    p["verbose"]       = get(p, "verbose", false)
    p["recursive"]     = get(p, "recursive", false)
    p["ignore-script"] = get(p, "ignore-script", false)
    p["run-test"]      = get(p, "run-test", false)
    p["dry-run"]       = get(p, "dry-run", false)
    max_workers        = sum(l -> match(r"^nixbld[0-9]+:", l) !== nothing, readlines(`getent passwd`))
    p["workers"]       = max(1, min(max_workers, get(p, "workers", 1)))
    p["no-update-julia-registries"] = get(p, "no-update-julia-registries", false)
    return p
end

function validate_config(config::AbstractDict)
    # TODO does this make sense?
    # if get(config, "recursive", true) && haskey(config, "names")
    #     nixsourcerer_error("Cannot specify 'recursive' and 'names' at the same time")
    # end
end

default_config() = parse_config(Dict())

prefix_name(name) = "source-" * name

function replace_variables(s::String, vars::Dict)
    for (k, v) in vars
        p = "@{{ $k }}"
        s = replace(s, p => v       )
    end
    return s
end

function tryparse_version(ver)
    parsed = tryparse(VersionNumber, ver)
    return parsed === nothing ? ver : string(parsed)
end

function run_jobs(jobs; workers=1)
    if workers == 1
        foreach(job -> job(), jobs) 
    else
        asyncmap(job -> job(), jobs; ntasks=workers)
    end
    return nothing
end

printstyledln(io::IO, args...; kwargs...) = printstyled(io, args..., '\n'; kwargs...)
printstyledln(args...; kwargs...) = printstyledln(stdout, args...; kwargs...)

indented_printstyled(args...; kwargs...) = indented_printstyled(stdout, args...; kwargs...)
function indented_printstyled(io::IO, args...; kwargs...)
    pad = repeat(' ', get(io, :indent, 0))
    printstyled(io, pad, args...; kwargs...)
end

indented_printstyledln(args...; kwargs...) = indented_printstyledln(stdout, args...; kwargs...)
indented_printstyledln(io::IO, args...; kwargs...) = indented_printstyled(io, args..., '\n'; kwargs...)

function Base.setindex(x::AbstractDict, v, k)
    y = copy(x)
    y[k] = v
    return y
end
