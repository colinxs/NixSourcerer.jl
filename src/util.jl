function subset(d::AbstractDict, keys...) 
    Dict{String,Any}(k => d[k] for k in keys if haskey(d, k))
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


