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
      julia = murpkgs.julia.latest;
    in {
      defaultApp = pkgs.callPackage ./default.nix { inherit julia; };
    };
}


