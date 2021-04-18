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

  doFetch = {git-tree-sha1, sha256, url}:
    let
      src = fetchurl { inherit sha256 url; };
    in
    # { "${git-tree-sha1}" = "file://${src}"; };
    { "${git-tree-sha1}" = src; };

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
        # map (v: doFetch { inherit (v) sha256 url; inherit (entry) git-tree-sha1; }) entry.download;
        { "${entry.git-tree-sha1}" = entry.download; };
  
  getOverrideableFromArtifactsFile = f: getOverrideable (attrValues (lib.importTOML f));
  overrideable = builtins.filter (x: x != {}) (lib.lists.flatten (map getOverrideableFromArtifactsFile juliaArtifactsFiles_));
  merged = lib.foldAttrs (n: a: trace n (n ++ a)) [] overrideable;
  newArtifacts = trace merged merged;

  format = formats.toml { };
  # overrides = lib.lists.flatten (map fn (attrValues (lib.importTOML juliaArtifactsFile)));
  # newArtifacts = lib.foldl' (a: b: a // b) {} overrides;
  # newArtifacts = trace (map typeOf overrides) (lib.importTOML juliaArtifactsFile);
  # overrides = lib.lists.flatten (lib.mapAttrsToList fn (lib.importTOML juliaArtifactsFile));
in
# writeText "output${builtins.toString builtins.currentTime}" json
  # writeText "output" json
format.generate "Overrides.toml" merged

# stdenv.mkDerivation ({
# } // (builtins.removeAttrs args [
# ]))

