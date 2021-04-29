{ system ? builtins.currentSystem, home ? import <home> }:

let
  pkgs = home.legacyPackages."${system}";
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    mur.julia-bin.latest
    git
    nix
    nix-prefetch
    nixpkgs-fmt
    cacert # Needed for network access
  ];
}

