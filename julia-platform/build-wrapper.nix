{ lib, dev, julia, curl, git, cacert }: 

{ defaultDepots ? true
, temporaryDepot ? false
, extraDepotPaths ? [ ]
, loadPath ? [ "@" "@v#.#" "@stdlib" ]
, activeProject ? null
, startupFile ? true

, extraPackages ? [ ]
, extraLibraries ? [ ]
, extraWrapperArgs ? {}
}:

# The first element of JULIA_DEPOT_PATH needs to be writable.
assert !defaultDepots -> (temporaryDepot || extraDepotPaths != [ ]);

let
  inherit (lib) optional optionalString optionalAttrs;

  depotPath =
    optional temporaryDepot "$(mktemp -d)"
    ++ optional defaultDepots ":"
    ++ extraDepotPaths;

  wrapperArgs = [ extraWrapperArgs {
    package = julia;
    extraLibraries = extraLibraries;
    # Some versions of Julia require curl + git
    # cacert needed for network access
    extraPackages = [ julia curl git cacert ] ++ extraPackages;
    prefix = {
      JULIA_DEPOT_PATH = { sep = ":"; vals = depotPath; };
      JULIA_LOAD_PATH = { sep = ":"; vals = loadPath; };
    };
    set = optionalAttrs (activeProject != null) {
      JULIA_PROJECT = "${activeProject}";
    };
    args = optional (! startupFile) "--startup-file=no";
  }];
in
dev.mkWrapper wrapperArgs
