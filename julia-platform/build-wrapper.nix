{ lib, julia, stdenv, makeWrapper, curl, writeText, git, runCommand, python3}:

{ julia
, depot ? null
, depots ? []

, defaultDepots ? true
, temporaryDepot ? true
, extraDepotPaths ? []
, primaryDepotPath ? null

, activateEnvironment ? true 
, pureLoadPath ? true

, extraPackages ? []
, extraLibs ? []
, makeWrapperArgs ? []
, ... }:

assert depot == null -> depots != [];

# One or the other, not both
assert primaryDepotPath != null -> ! temporaryDepot;
assert temporaryDepot -> primaryDepotPath == null;

# At least one path in JULIA_DEPOT_PATH needs to be writable
assert (primaryDepotPath == null && !temporaryDepot) -> defaultDepots;

let
  inherit (lib) optional optionals;

  finalDepots = if depot != null then [ depot ] else depots;
    
  # Some versions of Julia require curl + git
  finalExtraPackages = extraPackages ++ [ curl git ];

  primaryProject = 
    let active = lib.head finalDepots;
    in "${active}/environments/${active.name}";

  # The first element of JULIA_DEPOT_PATH needs to be writable.
  # If temporaryDepot or primaryDepotPath then we want 
  # (primaryDepotPath|temporaryDepot):finalDepots:defaultDepots:extraDepotPaths
  # defaultDepots:finalDepots:extraDepotPaths
  # temporaryDepot gets prepended below iff !primaryDepotPath
  juliaDepotPath =
    optional (primaryDepotPath != null) primaryDepotPath
    ++  (if primaryDepotPath == null && ! temporaryDepot then
          optional defaultDepots ":" ++ finalDepots ++ extraDepotPaths 
        else
          finalDepots ++ optional defaultDepots ":" ++ extraDepotPaths);

  setupTemporaryEnvironment = writeText "setupTemporaryEnvironment" ''
    depot="$(mktemp -d)"
    name="$(basename ${primaryProject})"

    mkdir -p $depot/environments
    cp -r ${primaryProject} $depot/environments
    chmod +w $depot/environments/$name/Manifest.toml
    chmod +w $depot/environments/$name/Project.toml
    export JULIA_DEPOT_PATH=$depot:$JULIA_DEPOT_PATH
    ${lib.optionalString activateEnvironment ''
      export JULIA_PROJECT="$depot/environments/$(basename ${primaryProject})"
    ''}
  '';
  
  # Wrapped Julia with libraries and environment variables.
  # Note: setting The PYTHON environment variable is recommended to prevent packages
  # from trying to obtain their own with Conda.
  finalMakeWrapperArgs = [
    # The extra ':' in JULIA_LOAD_PATH will be expanded to default load path
    "--suffix-each JULIA_DEPOT_PATH : '${lib.concatStringsSep " " juliaDepotPath}'"
    "--suffix LD_LIBRARY_PATH : '${lib.makeLibraryPath extraLibs}'"
    "--suffix PATH : '${lib.makeBinPath finalExtraPackages}'"
    "--set PYTHON '${python3}/bin/python'"
    # TODO after Julia 1.7 you'll be able to do JULIA_PROJECT=@name like in the REPL
  ] ++ optional activateEnvironment "--set JULIA_PROJECT '${primaryProject}'"
    ++ optional temporaryDepot "--run 'source ${setupTemporaryEnvironment}'"
    ++ optional pureLoadPath "--set JULIA_LOAD_PATH '@:@stdlib'"
    ++ makeWrapperArgs;

  finalJulia = runCommand "julia-wrapped" { 
      nativeBuildInputs = [makeWrapper]; 
      buildInputs = extraLibs ++ extraPackages;
      passthru = { depots = finalDepots; };
    } ''
    mkdir -p $out/bin
    makeWrapper ${julia}/bin/julia $out/bin/julia ${lib.concatStringsSep " " finalMakeWrapperArgs}
  '';

in
finalJulia
