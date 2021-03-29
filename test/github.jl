module TestGit 

include("preamble.jl")

@testset "github" begin
    owner = "nmattia"
    repo = "niv"
    rev = "62fcf7d0859628f1834d84a7a0706ace0223c27e"
    tag = "v0.2.19"
    git_url = "https://github.com/$(owner)/$(repo).git"
    tarball_url = "https://github.com/$(owner)/$(repo)/archive/$(rev).tar.gz"
    sha256 = with_clone_and_checkout(nix_dir_sha256, git_url, rev)

    toml = Dict(
        "test1" => Dict(
            "type" => "github",
            "owner" => owner,
            "repo" => repo,
            "rev" => rev
        ),
        "test2" => Dict(
            "type" => "github",
            "owner" => owner,
            "repo" => repo,
            "rev" => rev,
            "builtin" => true,
        ),
        "test3" => Dict(
            "type" => "github",
            "owner" => owner,
            "repo" => repo,
            "rev" => rev,
            "submodule" => true,
        ),
    )
    truth = Dict(
        "test1.fetcherName" => "pkgs.fetchzip", 
        "test1.fetcherArgs.url" => tarball_url,
        "test1.fetcherArgs.sha256" => sha256,
        
        "test2.fetcherName" => "builtins.fetchTarball", 
        "test2.fetcherArgs.url" => tarball_url,
        "test2.fetcherArgs.sha256" => sha256,
        
        "test3.fetcherName" => "pkgs.fetchgit", 
        "test3.fetcherArgs.url" => git_url,
        "test3.fetcherArgs.rev" => rev,
        "test3.fetcherArgs.sha256" => sha256,
    )
    runtest(toml, truth)
end

end



