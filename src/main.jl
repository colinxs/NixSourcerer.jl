using NixSourcerer

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "path"
            help = "path containing Sources.nix to update"
            required = true
    end

    return parse_args(s)
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

function main()
    args = parse_commandline()
    update(args["path"])
    return nothing
end

