using NixSourcerer
using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "path"
            help = "Environment to update"
            required = false
            arg_type = String
            default = pwd()
        "-n", "--names"
            help = "Source names to update in PATH"
            required = false
            arg_type = String
            nargs = '+'
        "-r", "--recursive"
            help = "Recursively update all environments under PATH"
            action = :store_true
        "-w", "--workers"
            help = "Number of worker threads to use"
            required = false
            arg_type = Int
            default = 1
    end
    
    return parse_args(s)
end

function main()
    args = parse_commandline()
    update(args["path"]; config=delete!(args, "path"))
    return nothing
end
