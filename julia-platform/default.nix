{ callPackage }:

# TODO rec
rec {
  fetchJuliaPackage   = callPackage ./fetch-package.nix { };
  fetchJuliaArtifact  = callPackage ./fetch-artifact.nix { };
  buildJuliaDepot     = callPackage ./build-depot.nix { };
  buildJuliaPackage   = callPackage ./build-package.nix { inherit buildJuliaDepot; };
  buildJuliaOverrides = callPackage ./build-overrides.nix { };
  buildJuliaWrapper   = callPackage ./build-wrapper.nix { };
}

