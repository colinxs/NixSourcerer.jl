module TestCrate

include("preamble.jl")

@testset "create" begin
    pname = "lscolors"
    version = "0.7.1"
    url = "https://crates.io/api/v1/crates/$(pname)/$(version)/download#crate.tar.gz"
    sha256 = with_unpack(nix_dir_sha256, download(url), strip = true)

    toml = Dict(
        "test1" => Dict(
            "type" => "crate",
            "pname" => pname,
            "version" => version,
            "url" => url,
        ),
        "test2" => Dict(
            "type" => "crate",
            "pname" => pname,
            "version" => version,
            "url" => url,
            "builtin" => true,
        ),
        "test3" => Dict(
            "type" => "crate",
            "pname" => pname,
            "version" => "latest",
            "url" => url,
        ),
    )
    truth = Dict(
        "test1.fetcherName" => "pkgs.fetchzip", 
        "test1.fetcherArgs.url" => url,
        "test1.fetcherArgs.sha256" => sha256,
        
        "test2.fetcherName" => "builtins.fetchTarball", 
        "test2.fetcherArgs.url" => url,
        "test2.fetcherArgs.sha256" => sha256,
        
        "test3.fetcherName" => "pkgs.fetchzip", 
        "test3.fetcherArgs.url" => url,
        "test3.fetcherArgs.sha256" => sha256,
    )
    runtest(toml, truth)
end

end

