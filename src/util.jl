subset(d::AbstractDict, keys...) = Dict{String,Any}(k => d[k] for k in keys if haskey(d, k))


function get_sha256(expr::String, args::Vector{String} = [ "--hash-algo", "sha256" ])
    expr = 
    """
    with (import <nixpkgs> { });
    $expr
    """
    cmd = `nix-prefetch $expr --output raw $args`
    run_suppress(cmd, out=true)
end

function get_sha256(fetcher_name::String, fetcher_args::Dict{Symbol,Any})
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
        return run_suppress(`nix-prefetch $args`, out=true)
    else
        expr = "$fetcher_name $(Nix.print(fetcher_args))"
        return get_sha256(expr)
    end
    # stdin = IOBuffer(JSON.json(fetcher_args))
    # stderr = IOBuffer()
    # cmd = pipeline(
    #     `nix-prefetch $fetcher_name --hash-algo sha256 --output raw --input json`; stdin, stderr
    # )
    # try
    #     strip(read(cmd, String))
    # catch
    #     str = sprint() do io
    #         for (k, v) in fetcher_args
    #             println(io, k, '=', v)
    #         end
    #     end
    #     msg = """
    #     Failed to run nix-prefetch for fetcher: $fetcher_name
    #     Arguments:
    #
    #     $(str)
    #
    #     Error message:
    #
    #     $(String(take!(stderr)))
    #     """
    #     nixsourcerer_error(msg)
    #     rethrow()
    # end
end

function get_cargosha256(pkg)
    # Not sure what exactly to override here..
    # See: https://github.com/Mic92/nix-update/issues/55
    stderr = IOBuffer()
    expr = "{ sha256 }: $(pkg).cargoDeps.overrideAttrs (_: { inherit sha256; cargoSha256 = sha256; outputHash = sha256; })"
    cmd = pipeline(`nix-prefetch --hash-algo sha256 --output raw $expr`; stderr)
    try
        strip(read(cmd, String))
    catch
        msg = """
        Failed to fetch cargosha256 for package: $pkg
        Error message:

        $(String(take!(stderr)))
        """
        nixsourcerer_error(msg)
        rethrow()
    end
end

function get_yarn_sha256(pkg)
    expr = "{ sha256 }: $(pkg).yarnDeps.overrideAttrs (_: { inherit sha256; yarnSha256 = sha256; outputHash = sha256; })"
    get_sha256(expr)
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

function run_julia_script(script_file::String)
    script_file = abspath(script_file)
    shell_file = joinpath(dirname(script_file), "shell.nix")
    cmd = if isfile(shell_file)
        `nix-shell --run "julia --project=. --color=yes --startup-file=no -O1 --compile=min $(script_file)"`
    else
        `julia --project=. --color=yes --startup-file=no -O1 --compile=min $(script_file)`
    end
    stderr = IOBuffer()
    cmd = pipeline(setenv(cmd; dir=dirname(script_file)); stderr)
    try
        strip(read(cmd, String))
    catch
        msg = """
        Failed to run Juila script at: $script_file
        Error message:

        $(String(take!(stderr)))
        """
        nixsourcerer_error(msg)
        rethrow()
    end
    return nothing
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

function sanitize_name(name)
    allowed=r"[^A-Za-z0-9+-._?=]"
    return replace(name, allowed => '_')
end

quote_string(s) = "'$s'"

function run_suppress(cmd; out=false)
    stdout = IOBuffer()
    cmd = pipeline(cmd; stdout)

    pty_slave, pty_master = open_fake_pty()
    p = run(cmd, pty_slave, pty_slave, pty_slave, wait=false)
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
        @error msg
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
    issubpath(path, cwd) ? relpath(path, cwd) : abspath(path)
end
