{ lib, stdenv, nix, nix-prefetch, nixpkgs-fmt, glibc, autoPatchelfHook, git, julia }:

stdenv.mkDerivation rec {
  pname = "nix-sourcerer";
  version = (lib.importTOML ./Project.toml).version;
  src = ./.;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontStrip = true;
  dontConfigure = true;

  buildInputs = [
    julia
    nix
    nix-prefetch
    nixpkgs-fmt
    glibc
    git
  ];

  buildPhase = ''
    julia --startup-file=no --project=scripts ./scripts/make.jl
  '';

  installPhase = ''
    mkdir $out
    cp -r ./build/* $out
  '';

}


