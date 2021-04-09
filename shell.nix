{ pkgs ? import <nixpkgs> { }, mur ? import <murpkgs> { inherit pkgs; inherit (pkgs) system; } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    mur.julia.latest
    nix
    nix-prefetch
    nixpkgs-fmt
    cacert # Needed for network access
  ];
}


