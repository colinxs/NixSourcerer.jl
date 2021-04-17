{ lib, stdenv, cacert, julia, curl }: 

let
  inherit (builtins) hasAttr;
  getName = path:
    let
      project = (lib.importTOML path);
      pname = if (hasAttr "name" project) then project.name else "NixDepot";
    in
    if (hasAttr "version" project) then "${pname}-${project.version}" else pname;
in
{ juliaProjectFile
, juliaManifestFile ? null
, name ? getName juliaProjectFile

, juliaRegistries ? {}
, juliaPkgServer ? null
, allowTOMLWrites ? false
, juliaUpdateHook ? ""

, patches ? []
, hash ? ""
, sha256 ? ""
, ...
} @ args:

let
  hasManifest = juliaManifestFile != null;
  depNames = builtins.attrNames (lib.importTOML juliaProjectFile).deps;
  hash_ =
    if hash != "" then { outputHashAlgo = null; outputHash = hash; }
    else if sha256 != "" then { outputHashAlgo = "sha256"; outputHash = sha256; }
    else throw "buildJuliaEnvironment requires a hash for ${name}";
in stdenv.mkDerivation ({
  inherit name;

  srcs = [ juliaProjectFile ] ++ (lib.optional hasManifest [ juliaManifestFile ]);

  nativeBuildInputs = [ cacert julia curl ];

  # Let's leave the _jll's alone
  dontStrip = true;

  # TODO checkPhase vs doCheck?
  phases = "unpackPhase patchPhase configurePhase buildPhase installPhase checkPhase";

  unpackPhase = ''
    cp $juliaProjectFile Project.toml
    ${lib.optionalString hasManifest ''
      cp $juliaManifestFile Manifest.toml
    ''}
  '';

  configurePhase = ''
    # NOTE Julia doesn't currently use this
    export SOURCE_DATE_EPOCH=1

    export JULIA_DEPOT_PATH="$(mktemp -d julia-depot.XXX)"
    export JULIA_PROJECT="$(pwd)"

    ${lib.optionalString (juliaPkgServer != null) ''
      export JULIA_PKG_SERVER="${juliaPkgServer}"
    ''}
   
    # We're not including the cache so don't create it
    export JULIA_PKG_PRECOMPILE_AUTO=0
   
    # Pkg.instantiate() will write the Project if Manifest doesn't exist? 
    # By default the sources are read-only
    ${lib.optionalString allowTOMLWrites ''
      chmod +w Project.toml
      if [[ -f Manifest.toml ]]; then
        chmod +w Manifest.toml
      fi
    ''}
    
    echo "Setup Julia registries"
    ${lib.optionalString (juliaRegistries != {}) (
      let
        specs = map (path: "RegistrySpec(path=\"${path}\")") juliaRegistries;
        cmd = "julia -e 'using Pkg; Pkg.Registry.add([${lib.concatStringsSep "," specs}])'"; 
      in cmd)}
  '';

  buildPhase = ''
    ${juliaUpdateHook}

    # TODO lazy artifacts
    # TODO resolve?
    # julia -e 'using Pkg; Pkg.instantiate(update_registry=false)'
  '';

  installPhase = ''
    # Ignoring:
    #   - clones: nix store is immutable so no point in including a git repo
    #   - compiled: .ji files are non-deterministic and non-portable
    #   - config: It's empty
    #   - dev: Manifest's with paths aren't supported
    #   - logs: obvious
    #   - scratchspaces: these are supposed to be mutable stores, so no
    # Which leaves:
    #   - artifacts: content hashed + immutable, should be portable
    #     except for '.pkg/select_artifacts' in 1.6+
    #   - registries: needed for resolver and Julia shouldn't
    #       try and update them since they don't have a .git
    #   - packages: duh
    mkdir $out
    for x in packages artifacts registries; do
      src="$JULIA_DEPOT_PATH/$x"
      if [[ -d $src ]]; then
        cp -r $src $out
      fi
    done

    # Create an environment accessing by 'Pkg.activate("@${name}", shared=true)'
    mkdir -p $out/environments/${name}
    cp Project.toml $out/environments/${name}
    cp Manifest.toml $out/environments/${name}
  '';

  doCheck = true;
  checkPhase = ''
    export JULIA_DEPOT_PATH="$(mktemp -d julia-depot.XXX):$out"
    export JULIA_LOAD_PATH="@${name}"
    julia -e 'using ${lib.concatStringsSep "," depNames}; @info "Success!"'
  '';

  inherit (hash_) outputHashAlgo outputHash;
  outputHashMode = "recursive";

} // (builtins.removeAttrs args [
  "name" "sha256" "juliaRegistries" "allowTOMLWrites"
]))

