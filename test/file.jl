module TestFile

include("preamble.jl")

@testset "file" begin
    url = "https://julialang-s3.julialang.org/bin/versions.json"
    sha256 = nix_file_sha256(download(url))
    toml = Dict(
        "test1" => Dict(
            "type" => "file",
            "url" => url,
            "builtin" => false,
        ),
        
        "test2" => Dict(
            "type" => "file",
            "url" => url,
        ),
    )
    truth = Dict(
        "test1.fetcherName" => "pkgs.fetchurl", 
        "test1.fetcherArgs.url" => url,
        "test1.fetcherArgs.sha256" => sha256,
        
        "test2.fetcherName" => "builtins.fetchurl", 
        "test2.fetcherArgs.url" => url,
        "test2.fetcherArgs.sha256" => sha256,
    )
    runtest(toml, truth)
end

end
