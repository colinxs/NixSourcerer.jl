{ stdenv
, lib
, buildPackages
, cacert
, fetchJuliaDepot
, callPackage
, git
, julia
}:

# { pname ? (lib.importTOML "${src}/Project.toml").name
# , version ? (lib.importTOML "${src}/Project.toml").name
{ name ? "${args.pname}-${args.version}"
  # SRI hash
, juliaHash ? ""

  # Legacy hash
, juliaSha256 ? ""

, juliaRegistries ? []
, src ? null
, unpackPhase ? null
, juliaPatches ? []
, patches ? []
, sourceRoot ? null
, logLevel ? ""
, buildInputs ? []
, nativeBuildInputs ? []
, juliaUpdateHook ? ""
, juliaDepotHook ? ""
, meta ? {}
, juliaVendorDir ? null
, depsExtraArgs ? {}

, ... } @ args:


assert juliaVendorDir == null -> !(juliaSha256 == "" && juliaHash == "");

let

  # juliaDepot = if juliaVendorDir == null
  #   then fetchJuliaDepot ({
  #       inherit src unpackPhase juliaUpdateHook;
  #       hash = juliaHash;
  #       patches = juliaPatches;
  #       sha256 = juliaSha256;
  #     } // depsExtraArgs)
  #   else null;

  # pname = (lib.importTOML "${src}/Project.toml").name;
  # version = (lib.importTOML "${src}/Project.toml").name;

  # If we have a juliaSha256 fixed-output derivation, validate it at build time
  # against the src fixed-output derivation to check consistency.
  validatejuliaDepot = !(juliaHash == "" && juliaSha256 == "");
in

stdenv.mkDerivation ((removeAttrs args ["depsExtraArgs"]) // {
  # inherit juliaDepot buildInputs;
  inherit buildInputs;

  name = args.name or "${args.pname}-${args.version}";

  nativeBuildInputs = nativeBuildInputs ++ [
    cacert
    julia
    git 
  ];

  patches = juliaPatches ++ patches;

  postUnpack = ''
    eval "$juliaDepotHook"
  '' + (args.postUnpack or "");

  configurePhase = args.configurePhase or ''
    runHook preConfigure
    runHook postConfigure
  '';

  # tar xf ${juliaDepot} -C $JULIA_DEPOT_PATH
  buildPhase = ''
    # set -ex

    export JULIA_DEPOT_PATH=$(mktemp -d julia-depot.XXX)
    # export JULIA_PROJECT=$(pwd)

    ${lib.optionalString (juliaRegistries != []) ''
      git clone https://github.com/colinxs/JuliaRegistry.git
      julia -e 'using Pkg; Pkg.Registry.add(${lib.concatMapStringsSep "," (r: "RegistrySpec(url=\"${r}\")") juliaRegistries})'
      julia -e 'using Pkg; Pkg.Registry.add("General")'
    ''}

    julia --startup-file=no -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate(); Pkg.precompile(strict=true)' 

    #export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
    # export JULIA_PROJECT=$(pwd)
  '';

  installPhase = ''
    mkdir $out
    cp -r $JULIA_DEPOT_PATH $out
  '';

  # doCheck = args.doCheck or true;

  # strictDeps = true;

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = juliaSha256;


  # passthru = { inherit juliaDepot; } // (args.passthru or {});

  meta = {
  } // meta;
})
