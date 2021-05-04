{ lib, pkgs, stdenv, cacert, julia, curl }: 

let
in
{ depot 
, name ? "julia-depot" 
, ...
} @ args:

let
  buildDepotEntry = path: src: 
    pkgs.runCommandLocal "depot-entry" {} ''
      dst="$out/${path}"
      mkdir -p $dst
      cp -r ${src}/* $dst
      ls -la $out
    '';
  mysrcs = lib.mapAttrsToList buildDepotEntry depot.depot;
in pkgs.symlinkJoin { inherit name; paths = mysrcs; }
# in stdenv.mkDerivation (
#
# {
#   inherit name;
#   srcs = mysrcs;
#
#   nativeBuildInputs = [ cacert julia curl ];
#
#   # Let's leave the _jll's alone
#   dontStrip = true;
#
#   # TODO checkPhase vs doCheck?
#   # phases = "unpackPhase installPhase checkPhase";
#   phases = "installPhase checkPhase";
#
#   installPhase = ''
#     mkdir $out
#     cp -r * $out
#   '';
#   
#   # TODO
#   checkPhase = "";
#   # doCheck = false;
#   # checkPhase = ''
#   #   export JULIA_DEPOT_PATH="$(mktemp -d julia-depot.XXX):$out"
#   #   export JULIA_LOAD_PATH="@${name}"
#   #   julia -e 'using ${lib.concatStringsSep "," depNames}; @info "Success!"'
#   # '';
# } // (builtins.removeAttrs args [
#   "depot"
# ]))
#

