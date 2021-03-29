module M

include("./src/NixSourcerer.jl")
using .NixSourcerer

function main()
    # path = ARGS[1]
    path = "$(@__DIR__)"
    update(path)
end

end

M.main()
