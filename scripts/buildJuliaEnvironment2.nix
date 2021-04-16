{ lib, stdenv, cacert, julia }: 

let 
in
{ src 
, patches ? []
, hash ? ""
, sha256 ? ""
, juliaUpdateHook ? ""
, juliaRegistries ? []
, ...
} @ args:

let 
  inherit (builtins) filterSource baseNameOf;
  name = "fuck";

  # project = lib.importTOML (src + "/Project.toml");
  # pname = (lib.importTOML (src + "/Project.toml")).name;
  # version = (lib.importTOML (src + "/Project.toml")).version;

  hash_ =
    if hash != "" then { outputHashAlgo = null; outputHash = hash; }
    else if sha256 != "" then { outputHashAlgo = "sha256"; outputHash = sha256; }
    else throw "buildJuliaEnvironment requires a hash for ${name}";
in stdenv.mkDerivation ({
  inherit src;
  name = "fuck";

  # src = filterSource (p: t: baseNameOf p == "Manifest.toml" || baseNameOf p == "Project.toml") src;


  nativeBuildInputs = [ cacert julia ];

  phases = "unpackPhase patchPhase configurePhase buildPhase installPhase";

  configurePhase = ''
  '';

  buildPhase = ''
    # Ensure deterministic Julia builds
    # TODO
    export SOURCE_DATE_EPOCH=1

    export JULIA_DEPOT_PATH=$(mktemp -d julia-depot.XXX)
    export JULIA_PROJECT=$(pwd)
    
    julia -e 'using Pkg; Pkg.Registry.add("General")'
    ${lib.optionalString (juliaRegistries != []) ''
      julia -e 'using Pkg; Pkg.Registry.add(${lib.concatMapStringsSep "," (r: "RegistrySpec(url=\"${r}\")") juliaRegistries})'
    ''}

    # Keep the original around for copyLockfile
    cp Manifest.toml Manifest.toml.orig

    ${juliaUpdateHook}

    julia -e 'using Pkg; Pkg.instantiate(); Pkg.precompile(strict=true)'

    # TODO
    # Add the Manifest.toml to allow hash invalidation
    cp Manifest.toml.orig $JULIA_DEPOT_PATH/Manifest.toml
  '';

  # Build a reproducible tar, per instructions at https://reproducible-builds.org/docs/archives/
  # installPhase = ''
  #   tar --owner=0 --group=0 --numeric-owner --format=gnu \
  #       --sort=name --mtime="@$SOURCE_DATE_EPOCH" \
  #       -C $JULIA_DEPOT_PATH \
  #       -czf $out . 
  # '';
  installPhase = ''
    mkdir $out
    cp -r . $out
  '';

  inherit (hash_) outputHashAlgo outputHash;
  outputHashMode = "recursive";

  impureEnvVars = lib.fetchers.proxyImpureEnvVars;
} // (builtins.removeAttrs args [
  "name" "sha256" "src"
]))


