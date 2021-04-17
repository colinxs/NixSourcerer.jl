{ lib, writeText, fetchurl, formats }: 

let
  
in

{ juliaArtifactsFile, ...} @ args:

let
  inherit (builtins) trace isAttrs hasAttr attrNames attrValues typeOf;
  # isDownload = x: (isAttrs x) && (trace (attrNames x) ((hasAttr "url" x) && (hasAttr "sha256" x)));
  # isDownload = x: (builtins.isAttrs x) false;
  # isDownload = x: false;
  doFetch = entry: 
    let
      src = fetchurl { inherit (entry) url sha256; };
    in
    entry // { url = "file://${src}"; };
  #cond = x: ! isDownload x;
  # cond = x: true;
  # isDownload = x: (hasAttr "url" x) && (hasAttr "sha256" x);
  # cond = x: trace (attrNames x) (! isDownload x);#( (builtins.any (x: (isAttrs x) || (builtins.isList x)) (attrValues x)));
  cond = x: true;
  fn = name_path: value: 
    # trace (builtins.typeOf value) (
    trace name_path (
    # (
    # trace ((builtins.head (lib.reverseList name_path)) == "download") 
    if ((builtins.head (lib.reverseList name_path)) == "download") then
      map (x: doFetch x) value 
    else
      if (builtins.isList value) then
        map (x: lib.mapAttrsRecursiveCond cond fn x) value
      else
        value);
  # cond = 
  format = formats.toml {};
  newArtifacts = lib.mapAttrsRecursiveCond cond fn (lib.importTOML juliaArtifactsFile);

  # json = builtins.toJSON newArtifacts;
in 
# writeText "output${builtins.toString builtins.currentTime}" json
# writeText "output" json
format.generate "Project.toml" newArtifacts

# stdenv.mkDerivation ({
# } // (builtins.removeAttrs args [
# ]))

