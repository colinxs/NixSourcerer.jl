{ lib, fetchurl, unzip }:

{ pkgName ? pname
, pname ? args.uuid 
, version ? args.treeHash
, uuid
, treeHash
, server ? https://pkg.julialang.org
, sha256
, ... } @ args:

assert pname == null || pname == pkgName;

lib.overrideDerivation (fetchurl ({

  name = "${pkgName}-${version}.tar.gz";
  url = "${server}/package/${uuid}/${treeHash}";
  recursiveHash = true;

  downloadToTemp = true;

  postFetch =
    ''
      export PATH=${unzip}/bin:$PATH

      unpackDir="$TMPDIR/unpack"
      mkdir "$unpackDir"
      cd "$unpackDir"

      renamed="$TMPDIR/${pkgName}-${version}.tar.gz"
      mv "$downloadedFile" "$renamed"
      unpackFile "$renamed"
      mv "$unpackDir" "$out"
    '';
} // removeAttrs args [ "pkgName" "pname" "version" "uuid" "server" "treeHash" ]))
# Hackety-hack: we actually need unzip hooks, too
(x: {nativeBuildInputs = x.nativeBuildInputs++ [unzip];})

