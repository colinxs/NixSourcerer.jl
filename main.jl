module M

include("./src/Sourcerer.jl")
using .Sourcerer

function main()
    # path = ARGS[1]
    path = "$(@__DIR__)"
    Sourcerer.process_dir(path)
end

end

M.main()
