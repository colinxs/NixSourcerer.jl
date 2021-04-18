{ lib, writeText, stdenv, fetchurl, formats }:

let

in

{ juliaArtifactsFile ? null
, juliaArtifactsFiles ? []
, ... } @ args:

let
  inherit (builtins) trace isList isAttrs hasAttr attrNames attrValues typeOf;

  juliaArtifactsFiles_ =
    if juliaArtifactsFiles == [] then
      if juliaArtifactsFile != null then
        [ juliaArtifactsFile ]
      else throw "buildOverrides requires either juliaArtifactsFile or juliaArtifactsFiles to be set"
    else
      juliaArtifactsFiles;

  targetPlatform = stdenv.targetPlatform.parsed;
  targetArch = targetPlatform.cpu.name;
  targetOs = targetPlatform.kernel.name;

  doFetch = git-tree-sha1: downloads:
    let
      # TODO multiple sha256? Multiple urls if same sha256?
      inherit (lib.head downloads) sha256 url;
    in
    fetchurl { inherit sha256 url; };

  getOverrideable = entry:
    if isList entry then
      map getOverrideable entry
    else
      if (hasAttr "lazy" entry) && entry.lazy
        || ((hasAttr "arch" entry) && (entry.arch != targetArch))
        || ((hasAttr "os" entry) && (entry.os != targetOs))
        || !(hasAttr "download" entry)
      then
        {}
      else
        { "${entry.git-tree-sha1}" = entry.download; };
  getOverrideableFromArtifactsFile = f: getOverrideable (attrValues (lib.importTOML f));

  overrideable = builtins.filter (x: x != {}) (lib.lists.flatten (map getOverrideableFromArtifactsFile juliaArtifactsFiles_));
  merged = lib.foldAttrs (n: a: n ++ a) [] overrideable;
  newArtifacts = lib.mapAttrs doFetch merged;

  format = formats.toml { };
in
# writeText "output${builtins.toString builtins.currentTime}" json
  # writeText "output" json
format.generate "Overrides.toml" newArtifacts

# stdenv.mkDerivation ({
# } // (builtins.removeAttrs args [
# ]))

