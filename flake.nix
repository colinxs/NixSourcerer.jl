{
  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  inputs.general-registry = {
    url = "github:JuliaRegistries/General";
    flake = false;
  };
  
  inputs.personal-registry = {
    url = "github:colinxs/JuliaRegistry";
    flake = false;
  };
  
  inputs.nix-home = {
    # url = "path:/home/colinxs/nix-home";
    url = "git+ssh://git@github.com/colinxs/home?ref=flake&dir=nix-home";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages."${system}";
      murpkgs = inputs.nix-home.legacyPackages."${system}".mur;
      julia = murpkgs.julia.latest;
      

      callPackage = pkgs.lib.callPackagesWith ( pkgs // { inherit julia callPackage; } );
      juliaPlatform = callPackage ./julia-platform {};
      depot = juliaPlatform.buildJuliaPackage { 
        src = ./.;
        juliaRegistries = with inputs; [ general-registry personal-registry ];
        sha256 = "1vbf4k5nck4wl73m09p6mbpr0f8rvkbcs21s02h3r9d07wsfwfx7";
      }; 
    in {
      defaultPackage."${system}" = juliaPlatform.buildJuliaWrapper {
        inherit depot julia;
        extraPackages = with pkgs; [ git nix nix-prefetch nixpkgs-fmt ];
        temporaryDepot = false;
        defaultDepots = true;
      };
    };
}


