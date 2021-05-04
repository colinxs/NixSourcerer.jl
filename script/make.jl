using Pkg
Pkg.instantiate()

using SnoopCompile
using NixSourcerer

tinf = @snoopi_deep begin
    include(joinpath(pkgdir(NixSourcerer), "test", "runtests.jl"))
end
ttot, pcs = SnoopCompile.parcel(tinf)

using PackageCompiler
mktempdir() do dir
    SnoopCompile.write(dir, pcs; always=true)
    files = readdir(dir; join=true)
    create_app(
        joinpath(@__DIR__, ".."),
        joinpath(@__DIR__, "..", "build");
        app_name="nix-sourcerer",
        precompile_statements_file=files,
        audit=true,
        force=true,
    )
end
