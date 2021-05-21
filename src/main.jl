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
        help = "Source names to update in `path`"
        required = false
        arg_type = String
        nargs = '+'
        default = nothing
        "-r", "--recursive"
        help = "Recursively update all environments under `path`"
        action = :store_true
        "-w", "--workers"
        help = "Number of worker threads to use"
        required = false
        arg_type = Int
        default = 1
        "--ignore-script"
        help = "Whether to skip any update.jl scripts and just update NixManifest"
        action = :store_true
        "--test"
        help = "Whether to run tests instead of update."
        action = :store_true
        "--verbose"
        help = "Enable debug output"
        action = :store_true
    end

    return parse_args(s)
end

function main()
    config = parse_commandline()
    path = config["path"]
    delete!(config, "path")
    isempty(config["names"]) && delete!(config, "names")
    if get(config, "test", false)
        test(path; config)
    else
        update(path; config)
    end
    return nothing
end

function julia_main()::Cint
    try
        main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end
