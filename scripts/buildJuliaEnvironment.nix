{ lib, stdenv, cacert, julia, curl, autoPatchelfHook, glibc, ripgrep, pcre2, gcc}: 

let 
  getName = path:
    let
      project = (lib.importTOML path);
    in
      "${project.name}-${project.version}";
in
{ juliaProject
, juliaManifest ? null
, juliaRegistries ? []

, allowTOMLWrites ? false
, doPatchElf ? false

, name ? getName juliaProject

, patches ? []
, hash ? ""
, sha256 ? ""
, juliaUpdateHook ? ""
, ...
} @ args:

let
  hasManifest = juliaManifest != null;
  hash_ =
    if hash != "" then { outputHashAlgo = null; outputHash = hash; }
    else if sha256 != "" then { outputHashAlgo = "sha256"; outputHash = sha256; }
    else throw "buildJuliaEnvironment requires a hash for ${name}";
in stdenv.mkDerivation ({
  # inherit name;
  pname = "foo";
  version = "1.0";

  srcs = [ juliaProject ] ++ lib.optional hasManifest [ juliaManifest ];

  # nativeBuildInputs = [ cacert julia curl ] ++ lib.optional doPatchElf [ autoPatchelfHook ];
  # nativeBuildInputs = [ cacert julia curl ]; 
  buildInputs = [ cacert julia curl ]; 
  disallowedRequisites = [];
  dontStrip = true;
  dontPatchShebangs =true;

  # nativeBuildInputs = [ cacert julia curl autoPatchelfHook]; 
  # buildInputs = [
  #   glibc
  #   pcre2
  #   gcc
  #   stdenv.cc.cc.lib
  # ];

  # TODO checkPhase
  phases = "unpackPhase patchPhase buildPhase installPhase";

  unpackPhase = ''
    cp $juliaProject Project.toml
    ${lib.optionalString hasManifest ''
      cp $juliaManifest Manifest.toml
    ''}
  '';

  # noAuditTmpdir = true;

  buildPhase = ''
    # TODO
    # Pkg.instantiate() will write the Project if Manifest doesn't exist? 
    # By default the sources are read-only
    ${lib.optionalString allowTOMLWrites ''
      chmod +w Project.toml
      if [[ -f Manifest.toml ]]; then
        chmod +w Manifest.toml
      fi
    ''}
    export HOME=$(pwd)
    # export JULIA_DEPOT_PATH=$(mktemp -d julia-depot.XXX)
    export JULIA_DEPOT_PATH="$HOME/depot"
    export JULIA_PROJECT=$(pwd)

    julia -e 'using Pkg; Pkg.Registry.add("General")'
    ${lib.optionalString (juliaRegistries != []) ''
      julia -e 'using Pkg; Pkg.Registry.add(${lib.concatMapStringsSep "," (r: "RegistrySpec(url=\"${r}\")") juliaRegistries})'
    ''}

    ${juliaUpdateHook}

    julia -e 'using Pkg; Pkg.instantiate()'

    julia -e 'using Pkg; VERSION >= v"1.6" ? Pkg.precompile(strict=true) : Pkg.precompile()'
  '';

  installPhase = ''
    mkdir $out
    
    export SOURCE_DATE_EPOCH=1

    # Ignore config/environments/logs/registries from depot
    # for x in artifacts clones compiled dev packages scratchspaces; do
    for x in compiled artifacts clones dev packages scratchspaces; do
      src="$JULIA_DEPOT_PATH/$x"
      if [[ -d $src ]]; then
        cp -r $src $out
      fi
    done

    # Create an environment accessing by 'Pkg.activate("@${name}", shared=true)'
    mkdir -p $out/environments/${name}
    cp Project.toml $out/environments/${name}
    cp Manifest.toml $out/environments/${name}
    
    echo "========================="
    echo "=====yooooooooooooo="
    echo "========================="
    ${ripgrep}/bin/rg --binary "$TMPDIR" "$out" 
    echo "========================="
    echo "========================="
    ${ripgrep}/bin/rg --binary "$out" "$out/compiled"
    echo "========================="
    echo "========================="
    ${ripgrep}/bin/rg --binary "$(pwd)" "$out/compiled" 
    echo "========================="
    echo "========================="

    find $out -exec touch -m -d @1 {} +
  '';

  checkPhase = ''
    export JULIA_DEPOT_PATH="$(mktemp -d julia-depot.XXX):$out"
    julia -e 'using Pkg; Pkg.activate("@${name}")'
  '';

  inherit (hash_) outputHashAlgo outputHash;
  outputHashMode = "recursive";

} // (builtins.removeAttrs args [
  "name" "sha256"
]))

