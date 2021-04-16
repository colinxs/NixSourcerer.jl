{
  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  
  inputs.nix-home = {
    url = "path:/home/colinxs/nix-home";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages."${system}";
      murpkgs = inputs.nix-home.legacyPackages."${system}".mur;
      # julia = murpkgs.julia.latest;
      julia = murpkgs.julia."1.6.0";
      # julia = murpkgs.julia."1.5.4";
      # julia = pkgs.julia;
      buildJuliaEnvironment = pkgs.callPackage ./scripts/buildJuliaEnvironment.nix { inherit julia; };
      buildJuliaProject = pkgs.callPackage ./scripts/buildJuliaPackage.nix { inherit julia buildJuliaEnvironment; };
      # sha256 = "0cwcrr0zbgm65yzy2j3ipgddvj2kx719p1xamnw17jyf4a2fd4nl";
      # juliaRegistries = ["https://github.com/colinxs/JuliaRegistry.git"];
      juliaRegistries = [];
      # src = builtins.fetchGit {
      src = pkgs.fetchgit {
        sha256 = "1nsg61ysihdrxl3xg70v652pxkljqaka2dfr0rvrgckdw5axf55b";
        url= "https://github.com/JuliaArrays/StaticArrays.jl.git";
        rev= "5e5a7a8334f6a6d386885495cf8b74d7df6e68a2";
      };
      # sha256 = "1q2c47wxk974wk7yn6vrfbhz38h994n1dcdk1j7ajd7sghvr1h5k";
      # sha256 = "0hxzhjpx558a8m28k1parklb7cdy66nlq6xa89zxsrhg2wd6vdff";
    in {
      # defaultApp = pkgs.callPackage ./scripts/default.nix { inherit julia; };
      defaultPackage."${system}" = buildJuliaEnvironment { 
        inherit juliaRegistries; 
        sha256 = pkgs.lib.fakeSha256;
        # sha256 = "0iri6xg490n3z922l64yzx3bjy4fqs8rshshfaq7x0spz9d25j8b";
        name = "swag";
        # src = ./testenv;
        juliaProject=./testenv/Project.toml; 
        juliaManifest=./testenv/Manifest.toml; 
        # allowTOMLWrites = true;
        # doPatchElf = true;
        # juliaProject=./Project.toml; 
        # juliaManifest=./Manifest.toml; 
      }; 
      # defaultPackage."${system}" = buildJuliaProject { src = ./.; inherit juliaRegistries; juliaSha256 = sha256; name = "fooPackage"; }; 
    };
}


