{ lib, fetchurl, unzip }:

{ uuid
, treeHash 
, sha256
, server ? https://pkg.julialang.org
, ... } @ args:

assert builtins.trace "YOOOOO" true;

lib.overrideDerivation (fetchurl ({
  name = "${uuid}-${treeHash}.tar.gz";
  url = "${server}/package/${uuid}/${treeHash}";
  recursiveHash = true;
  downloadToTemp = true;
  postFetch =
    ''
      export PATH=${unzip}/bin:$PATH

      unpackDir="$TMPDIR/unpack"
      mkdir "$unpackDir"
      cd "$unpackDir"

      renamed="$TMPDIR/${uuid}-${treeHash}.tar.gz"
      mv "$downloadedFile" "$renamed"
      unpackFile "$renamed"
      mv "$unpackDir" "$out"
    '';
} // removeAttrs args [ "uuid" "treeHash" "server" ]))
# Hackety-hack: we actually need unzip hooks, too
# TODO???
(x: {nativeBuildInputs = x.nativeBuildInputs++ [unzip];})

