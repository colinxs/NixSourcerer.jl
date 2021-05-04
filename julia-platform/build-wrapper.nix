{ lib, julia, curl, git, cacert, makeWrapper, writeText, runCommandLocal }:

{ defaultDepots ? true
, temporaryDepot ? false 
, extraDepotPaths ? []
, loadPath ? ["@" "@v#.#" "@stdlib"]
, activeProject ? null
, startupFile ? true

, extraPackages ? []
, extraLibs ? []
, extraMakeWrapperArgs ? []
, ... }:

# The first element of JULIA_DEPOT_PATH needs to be writable.
assert !defaultDepots ->  (temporaryDepot || extraDepotPaths != []);

let
  inherit (lib) optional;
  makePath = xs: lib.concatStringsSep ":" xs;

  # temporaryDepot handled below
  depotPath = optional defaultDepots ":" ++ extraDepotPaths;
  mkTemporaryDepot = writeText "mkTemporaryDepot" ''
    TEMP_DEPOT="$(mktemp -d)"
    export JULIA_DEPOT_PATH="$TEMP_DEPOT''${JULIA_DEPOT_PATH:+:''${JULIA_DEPOT_PATH}}"
  '';
    
  # Some versions of Julia require curl + git
  # cacert needed for network access
  finalPackages = [ julia curl git cacert ] ++  extraLibs ++ extraPackages;
  
  # Wrapped Julia with libraries and environment variables.
  makeWrapperArgs = [
    "--prefix JULIA_DEPOT_PATH : '${makePath depotPath}'"
    "--prefix JULIA_LOAD_PATH : '${makePath loadPath}'"
    "--prefix PATH : '${lib.makeBinPath finalPackages}'"
    "--prefix LD_LIBRARY_PATH : '${lib.makeLibraryPath extraLibs}'"
  ] ++ optional temporaryDepot "--run 'source ${mkTemporaryDepot}'"
    ++ optional (activeProject != null) "--set JULIA_PROJECT '${activeProject}'"
    ++ optional (! startupFile) "--add-flags '--startup-file=no'"
    ++ extraMakeWrapperArgs;

  finalJulia = runCommandLocal "julia-wrapped" { 
      nativeBuildInputs = [ makeWrapper ]; 
      buildInputs = finalPackages; 

    } ''
    mkdir -p $out/bin
    makeWrapper ${julia}/bin/julia $out/bin/julia ${lib.concatStringsSep " " makeWrapperArgs}
  '';
in
finalJulia
