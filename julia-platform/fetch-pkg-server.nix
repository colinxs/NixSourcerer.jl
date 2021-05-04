{ lib, fetchurl, unzip }:

{ fullURL ? null
, endPoint ? null
, server ? "https://pkg.julialang.org"
, name ? "source"
, extraPostFetch ? ""
, ... } @ args:

assert (fullURL != null) -> endPoint == null;

(fetchurl (let
  filename = name + ".tar.gz";
  url = if fullURL != null then fullURL else server + "/${endPoint}";
in {
  inherit name url;

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
} // removeAttrs args [ "fullURL" "endPoint" "server" "extraPostFetch" ])).overrideAttrs (x: {
  # Hackety-hack: we actually need unzip hooks, too
  nativeBuildInputs = x.nativeBuildInputs ++ [ unzip ];
})
