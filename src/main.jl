using NixSourcerer
using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "path"
            help = "path to update"
            required = false
            arg_type = String
            default = pwd()
        "--recursive"
            action = :store_true
        "--ntasks"
            required = false
            arg_type = Int 
            default = 1
    end
    return parse_args(s)
end

function main()
    args = parse_commandline()
    update(args["path"], config = delete!(args, "path"))
    return nothing
end

