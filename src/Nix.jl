module Nix

struct NixText
    s::String
end

NixText(c::AbstractChar) = NixText(string(c))

print(io, x::NixText) = Base.print(io, x.s)

function print(x)
    io = IOBuffer()
    print(io, x)
    return String(take!(io))
end

function print(io, xs...)
    for x in xs
        print(io, x)
    end
    return nothing
end

print(io, x::Union{AbstractChar,AbstractString}) = Base.print(io, '"', x, '"')

print(io, x::Union{Integer,AbstractFloat}) = Base.print(io, x)

print(io, x::Bool) = Base.print(io, x ? "true" : "false")

print(io, x::Nothing) = Base.print(io, "null")

print(io, x::Symbol) = Base.print(io, string(x))

function print(io, x::Pair)
    print(io, x.first)
    write(io, " = ")
    print(io, x.second)
    write(io, ";")
    return nothing
end

function print(io, x::AbstractDict)
    write(io, '{')
    for (k, v) in x
        print(io, Pair(k, v))
    end
    write(io, '}')
    return nothing
end

function print(io, xs::Union{AbstractVector,Tuple})
    write(io, '[')
    for x in xs
        write(io, " (")
        print(io, x)
        write(io, ')')
    end
    write(io, ']')
    return nothing
end

function format(io::IO, x)
    open(`nixfmt`, "w", io) do stdin
        write(stdin, x)
    end
    return nothing
end

function format(x)
    str = sprint() do io
        format(io, x)
    end
    return str
end

end # module
