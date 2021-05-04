{ lib, fetchurl, unzip }:

{ treeHash
, sha256
, server ? https://pkg.julialang.org
, ... } @ args:

let
  version = treeHash;
in
lib.overrideDerivation (fetchurl ({
  name = "${treeHash}.tar.gz";
  url = "${server}/artifact/${treeHash}";
  recursiveHash = true;
  downloadToTemp = true;
  postFetch =
    ''
      export PATH=${unzip}/bin:$PATH

      unpackDir="$TMPDIR/unpack"
      mkdir "$unpackDir"
      cd "$unpackDir"

      renamed="$TMPDIR/${treeHash}.tar.gz"
      mv "$downloadedFile" "$renamed"
      unpackFile "$renamed"
      mv "$unpackDir" "$out"
    '';
} // removeAttrs args [ "treeHash" "server" ]))
# Hackety-hack: we actually need unzip hooks, too
# TODO ???
(x: {nativeBuildInputs = x.nativeBuildInputs++ [unzip];})


