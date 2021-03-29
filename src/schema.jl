struct SimpleSchema
    key::String
    type::Type
    required::Bool
end

function verify(schema::SimpleSchema, name, spec)
    if haskey(spec, schema.key)
        if ! (spec[schema.key] isa schema.type)
            error("Expected key \"$(schema.key)\" to be of type $(schema.type), got $(typeof(spec[schema.key]))")
        end
    elseif schema.required
        error("Must specify \"$(schema.key)\" for source $name")
    end
end


struct ExclusiveSchema{N}
    keys::NTuple{N,String}
    types::NTuple{N,DataType}
    required::Bool
end

function verify(schema::ExclusiveSchema, name, spec)
    idx = findfirst(k -> haskey(spec, k), schema.keys)
    if idx !== nothing
        key = schema.keys[idx]
        T = schema.types[idx]
        if !(spec[key] isa T)
            error("Expected key \"$(key)\" to be of type $(T), got $(typeof(spec[key]))")
        end
    elseif schema.required
        error("Must specify exactly one of ( $(join(map(x -> "\"$x\"", schema.keys), ", ")) ) for source $name")
    end
end


function verify(schemas, name, spec)
    all_keys = Set{String}()
    for schema in schemas
        verify(schema, name, spec)
    end
end






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
