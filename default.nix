{ lib, stdenv, nix, nix-prefetch, nixpkgs-fmt, git, mur }:

stdenv.mkDerivation rec {
  pname = "nix-sourcerer";
  version = (lib.importTOML ./Project.toml).version;
  src = ./.;

  buildInputs = [
    mur.julia.latest
    nix
    nix-prefetch
    nixpkgs-fmt
    git
  ];

  # buildPhase = ''
  #   julia ./scripts/make.jl
  # '';

  installPhase = ''
    mkdir -p $out/bin
    cp build/bin/${pname} $out/bin/${pname}
  '';

}


