



# TODO check extra keys
function verify_schema(schema, name, spec)
    all_keys = Set()
    for (keys, required) in schema
        if keys isa AbstractString
            push!(all_keys, keys)
        else
            union!(all_keys, keys)
            if required && count(!isnothing, map(k -> get(spec, k, nothing), keys)) != 1
                error("Must specify exactly one of ( $(join(map(x -> "\"$x\"", keys), ", ")) ) for source $name")
            end
        end
    end

    extra_keys = setdiff(keys(spec), all_keys)
    if length(extra_keys) > 0
        error("Unknown keys detected for source $name: ( $(join(map(x -> "\"$x\"", collect(extra_keys)), ", ")) )")
    end
end
