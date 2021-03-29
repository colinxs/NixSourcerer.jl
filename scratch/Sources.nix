{ pkgs ? import <nixpkgs> { } }: {
  archive_nixpkgs = let
    fetcher = pkgs.fetchzip;
    fetcherName = "pkgs.fetchzip";
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherName fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1617012508;
      original = {
        type = "archive";
        url =
          "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
      };
    };
  };
}
