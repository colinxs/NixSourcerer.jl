module TestFile

include("preamble.jl")

@testset "file" begin
    url = "https://julialang-s3.julialang.org/bin/versions.json"
    sha256 = nix_file_sha256(download(url))

    toml = Dict(
        "file1" => Dict(
            "type" => "file",
            "url" => url,
        ),
        "file2" => Dict(
            "type" => "file",
            "url" => url,
            "builtin" => true
        ),
    )

    truth = Dict(
        "file1.fetcherName" => "pkgs.fetchurl", 
        "file1.fetcherArgs.url" => url,
        "file1.fetcherArgs.sha256" => sha256,
        
        "file2.fetcherName" => "builtins.fetchurl", 
        "file2.fetcherArgs.url" => url,
        "file2.fetcherArgs.sha256" => sha256,
    )
    with_source_toml(toml) do dir
        update(dir)
        print(read("$dir/Sources.nix", String))
        # @test nix_eval_source_attr(dir, "file1.fetcherArgs.sha256") == truth["file1"]["sha256"]
        compare_source_attrs(dir, truth)
    end
end

end
