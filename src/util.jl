function subset(d::AbstractDict, keys...) 
    Dict{String,Any}(k => d[k] for k in keys if haskey(d, k))
end

quote_string(x::AbstractString) = "\"$(x)\""

function rundebug(cmd::Cmd, stdout::Bool=false)
    ioerr = IOBuffer()
    cmd = pipeline(cmd, stderr=ioerr)
    out = try
        if stdout
            read(cmd, String)
        else
            run(cmd)
            nothing
        end
    catch e
        @error String(take!(ioerr))
        rethrow()
    finally
        @debug String(take!(ioerr))
    end
    return out
end

# function safemerge(x::AbstractDict, y::AbstractDict)
#     for (k, v) in y
#         if haskey(x, k) && x[k] != y[k]
#             error("Key conflict: $k")
#         end
#     end
# end
#
# function safemerge(x::AbstractDict, ys::AbstractDict...)


