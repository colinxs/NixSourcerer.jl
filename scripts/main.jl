using NixSourcerer
using ArgParse

function julia_main()::Cint
    try
        NixSourcerer.main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

julia_main()
