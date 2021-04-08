subset(d::AbstractDict, keys...) = Dict{String,Any}(k => d[k] for k in keys if haskey(d, k))

function rundebug(cmd::Base.AbstractCmd; stdout::Bool=false)
    @debug "Running command: $cmd"
    ioerr = IOBuffer()
    cmd = pipeline(cmd, stderr=ioerr)
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

function get_sha256(fetcher, fetcherargs)
    @debug "Calling nix-prefetch" fetcher fetcherargs
    io = IOBuffer(JSON.json(fetcherargs))
    cmd = pipeline(`nix-prefetch $fetcher --hash-algo sha256 --output raw --input json`, stdin = io)
    return strip(rundebug(cmd; stdout=true))
end

function build_source(fetcher, fetcher_args)
    expr = "(with (import <nixpkgs> {}); ($fetcher $(Nix.print(fetcher_args))).outPath)"
    run(pipeline(`nix eval $expr`, stdout=devnull))
end

function run_julia_script(script_file::AbstractString)
    @info "Running script $script_file"
    run(setenv(`$script_file`, dir = dirname(script_file)))
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

