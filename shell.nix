{ pkgs ? import <nixpkgs> { }}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    git
    nix
    nix-prefetch
    nixpkgs-fmt
    cacert # Needed for network access
  ];
}

