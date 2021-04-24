subset(d::AbstractDict, keys...) = Dict{String,Any}(k => d[k] for k in keys if haskey(d, k))


function rundebug(cmd::Base.AbstractCmd; stdout::Bool=false)
    @debug "Running command: $cmd"
    ioerr = IOBuffer()
    cmd = pipeline(cmd; stderr=ioerr)
    try
        out = if stdout
            read(cmd, String)
        else
            run(cmd)
            nothing
        end
        @debug String(take!(ioerr))
        return out
    catch e
        nixsourcerer_error("Could not execute $cmd: \n", String(take!(ioerr)))
        rethrow()
    end
end

function get_sha256(fetcher_name, fetcherargs)
    @debug "Calling nix-prefetch" fetcher_name fetcherargs
    io = IOBuffer(JSON.json(fetcherargs))
    cmd = pipeline(
        `nix-prefetch $fetcher_name --hash-algo sha256 --output raw --input json`; stdin=io
    )
    return strip(rundebug(cmd, stdout = true))
end

function get_cargosha256(pkg)
    expr = "{ sha256 }: $(pkg).cargoDeps.overrideAttrs (_: { cargoSha256 = sha256; })"
    return strip(rundebug(`nix-prefetch --hash-algo sha256 --output raw $expr`, stdout=true))
end

function build_source(fetcher_name, fetcher_args)
    expr = "(with (import <nixpkgs> {}); ($fetcher_name $(Nix.print(fetcher_args))).outPath)"
    return run(pipeline(`nix eval $expr`; stdout=devnull))
end

function run_julia_script(script_file::AbstractString)
    script_file = abspath(script_file)
    shell_file = joinpath(dirname(script_file), "shell.nix")
    jlcmd = `julia --project=. --color=yes --startup-file=no -O1 --compile=min $(script_file)`
    cmd = isfile(shell_file) ? `nix-shell --run '$jlcmd'` : `$jlcmd`
    run(setenv(cmd; dir=dirname(script_file)))
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
