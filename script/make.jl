using Pkg
Pkg.instantiate()

using SnoopCompile
using NixSourcerer

# tinf = @snoopi_deep begin
#     include(joinpath(pkgdir(NixSourcerer), "test", "runtests.jl"))
# end
# ttot, pcs = SnoopCompile.parcel(tinf)

using PackageCompiler
mktempdir() do dir
    # SnoopCompile.write(dir, pcs; always=true)
    # files = readdir(dir; join=true)
    create_app(
        joinpath(@__DIR__, ".."),
        joinpath(@__DIR__, "..", "build");
        executables = [
            "nix-sourcerer" => "julia_main",
        ],
        # precompile_statements_file=files,
        force=true,
        incremental=true,
        include_transitive_dependencies=false,
        filter_stdlibs = false,
        cpu_target="native",
    )
end
