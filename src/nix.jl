function generate_nixexpr(entry_specs)
    fetcher_calls = []
    fetchers = Set()
    for name in sort(collect(keys(entry_specs)))
        fetcher, fetcherargs, meta = entry_specs[name]

        push!(fetcher_calls, format_entry(name, fetcher, fetcherargs, meta))
        if !startswith(fetcher, "builtins")
            push!(fetchers, fetcher)
        end
    end

    # TODO builtin source?
    signature = "{ pkgs ? import <nixpkgs> {} }:"
    srcs = "{ $(join(fetcher_calls, "\n")) }"
    nixexpr = "$signature $srcs"

    return nixfmt(nixexpr)
end

function format_entry(name, fetcher, fetcherargs, meta)
    name = to_nix_value(name)
    fetcher = to_nix_value(fetcher)
    fetcherargs = to_nix_value(fetcherargs) 
    meta = to_nix_value(meta)
    
    return """
    $(strip(name)) = let
        fetcher = $fetcher;
        fetcherName = $(quote_string(fetcher));
        fetcherArgs = $fetcherargs;
    in {
        inherit fetcher fetcherName fetcherArgs;
        src = fetcher fetcherArgs;
        meta = $meta;
    };
    """
end

function to_nix_value(x)
    expr = "(builtins.fromJSON \"$(escape_string(JSON.json(x)))\")"
    strip(rundebug(`nix eval "$expr"`, true))
end
to_nix_value(x::String) = strip(x)

function get_sha256(fetcher, fetcherargs)
    @debug "Calling nix-prefetch for fetcher $fetcher with args: $fetcherargs"

    err = IOBuffer()
    cmd = pipeline(`nix-prefetch $fetcher --hash-algo sha256 --output raw --input json`, stderr = err)
    sha256 = try
        open(cmd, IOBuffer(JSON.json(fetcherargs)), read=true) do p
            strip(read(p, String))
        end
    catch e
        @error String(take!(err))
        rethrow()
    finally
        @debug String(take!(err))
    end

    return sha256 
end

function nixfmt(nixexpr::String)
    stdin = IOBuffer(nixexpr)
    stdout = IOBuffer()
    stderr = IOBuffer()
    run(pipeline(`nixfmt`; stdin, stdout, stderr))
    @debug String(take!(stderr))
    return String(take!(stdout))
end
