{ lib, fetchurl, unzip }:

{ endPoint 
, server ? "https://pkg.julialang.org"
, name ? "source"
, sha256
, extraPostFetch ? ""
, ... } @ args:

let
  filename = name + ".tar.gz"; 
in
(fetchurl {
  inherit name sha256;

  url = server + endPoint;

  recursiveHash = true;

  downloadToTemp = true;

  postFetch = ''
    unpackDir="$TMPDIR/unpack"
    mkdir "$unpackDir"
    cd "$unpackDir"

    renamed="$TMPDIR/${filename}"
    mv "$downloadedFile" "$renamed"
    unpackFile "$renamed"
    mv "$unpackDir" "$out"
    
    ${extraPostFetch}
    # Remove non-owner write permissions
    # Fixes https://github.com/NixOS/nixpkgs/issues/38649
    chmod 755 "$out"
  '';
} // removeAttrs args [ "endPoint" "server" "extraPostFetch" ]).overrideAttrs (x: {
  # Hackety-hack: we actually need unzip hooks, too
  # TODO
  nativeBuildInputs = x.nativeBuildInputs ++ [ unzip ];
})
