module TestArchive

include("preamble.jl")

@testset "archive" begin
    url = "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz"
    sha256 = with_unpack(nix_dir_sha256, download(url), strip = true)
    toml = Dict(
        "test1" => Dict(
            "type" => "archive",
            "url" => url,
        ),
        "test2" => Dict(
            "type" => "archive",
            "url" => url,
            "builtin" => true
        ),
    )
    truth = Dict(
        "test1.fetcherName" => "pkgs.fetchzip", 
        "test1.fetcherArgs.url" => url,
        "test1.fetcherArgs.sha256" => sha256,
        
        "test2.fetcherName" => "builtins.fetchTarball", 
        "test2.fetcherArgs.url" => url,
        "test2.fetcherArgs.sha256" => sha256,
    )
    runtest(toml, truth)
end

end

