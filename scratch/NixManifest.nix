{ pkgs ? import <nixpkgs> { } }: {
  "crate_version_builtin" = let
    name = "lscolors-0.7.1";
    pname = "lscolors";
    version = "0.7.1";
    fetcher = builtins.fetchTarball;
    fetcherName = "builtins.fetchTarball";
    fetcherArgs = {
      "sha256" = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      "url" =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
    src = fetcher fetcherArgs;
    meta = { };
  in { inherit name pname version fetcher fetcherName fetcherArgs meta; };
  "archive_builtin" = let
    name =
      "archive_builtin-1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
    pname = "archive_builtin";
    version = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
    fetcher = builtins.fetchTarball;
    fetcherName = "builtins.fetchTarball";
    fetcherArgs = {
      "sha256" = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      "url" =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
    src = fetcher fetcherArgs;
    meta = { };
  in { inherit name pname version fetcher fetcherName fetcherArgs meta; };
}
