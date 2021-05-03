module Nix

struct NixText
    s::String
end

NixText(c::AbstractChar) = NixText(string(c))

print(io::IO, x::NixText) = Base.print(io, x.s)

function print(xs...)
    sprint() do io
        print(io, xs...)
    end
end

function print(io::IO, xs...)
    for x in xs
        print(io, x)
    end
    return nothing
end

print(io::IO, x) = print(io, string(x)) 

print(io::IO, x::Union{AbstractChar,AbstractString}) = Base.print(io, '"', x, '"')

print(io::IO, x::Union{Integer,AbstractFloat}) = Base.print(io, x)

print(io::IO, x::Bool) = Base.print(io, x ? "true" : "false")

print(io::IO, x::Nothing) = Base.print(io, "null")

print(io::IO, x::Symbol) = Base.print(io, string(x))

function print(io::IO, x::Pair)
    print(io, x.first)
    write(io, " = ")
    print(io, x.second)
    write(io, ";")
    return nothing
end

function print(io::IO, x::AbstractDict; sort::Bool = false)
    write(io, '{')
    ks = sort ? Base.sort(collect(keys(x))) : keys(x)
    for k in ks
        print(io, Pair(k, x[k]))
    end
    write(io, '}')
    return nothing
end

function print(io::IO, xs::Union{AbstractVector,Tuple})
    write(io, '[')
    for x in xs
        write(io, " (")
        print(io, x)
        write(io, ')')
    end
    write(io, ']')
    return nothing
end

nixfmt(io::IO, x) = _format(io, x, `nixfmt`)
nixpkgs_fmt(io::IO, x) = _format(io, x, `nixpkgs-fmt`)
function _format(io::IO, x, formatter::Cmd)
    open(formatter, "w", io) do stdin
        write(stdin, x)
    end
    return nothing
end

end # module
