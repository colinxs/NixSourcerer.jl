{ callPackage }:

# TODO rec
rec {
  fetchPkgServer      = callPackage ./fetch-pkg-server.nix { };
  buildJuliaDepot     = callPackage ./build-depot.nix { };
  buildJuliaPackage   = callPackage ./build-package.nix { inherit buildJuliaDepot; };
  buildJuliaOverrides = callPackage ./build-overrides.nix { };
  buildJuliaWrapper   = callPackage ./build-wrapper.nix { };
}

