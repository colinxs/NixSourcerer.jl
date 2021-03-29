{ pkgs ? import <nixpkgs> { } }: {
  github_branch = let
    fetcher = pkgs.fetchzip;
    fetcherArgs = {
      sha256 = "1qjavxabbrsh73yck5dcq8jggvh3r2jkbr6b5nlz5d9yrqm9255n";
      url =
        "https://github.com/nmattia/niv/archive/af958e8057f345ee1aca714c1247ef3ba1c15f5e.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616819146;
      original = {
        branch = "master";
        owner = "nmattia";
        repo = "niv";
        type = "github";
      };
      rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
    };
  };

  github_release = let
    fetcher = pkgs.fetchzip;
    fetcherArgs = {
      sha256 = "18c030bb65r50i6z37iy7jb9z9i8i36y7b08dbc9bchdifqsijs5";
      url =
        "https://github.com/tree-sitter/tree-sitter-bash/archive/df0f7bcd72c2a6632f8a15c0ba88972ec5e96878.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616819152;
      original = {
        owner = "tree-sitter";
        release = "latest";
        repo = "tree-sitter-bash";
        type = "github";
      };
      rev = "df0f7bcd72c2a6632f8a15c0ba88972ec5e96878";
    };
  };

  github_rev = let
    fetcher = pkgs.fetchzip;
    fetcherArgs = {
      sha256 = "1qjavxabbrsh73yck5dcq8jggvh3r2jkbr6b5nlz5d9yrqm9255n";
      url =
        "https://github.com/nmattia/niv/archive/af958e8057f345ee1aca714c1247ef3ba1c15f5e.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616819140;
      original = {
        owner = "nmattia";
        repo = "niv";
        rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
        type = "github";
      };
      rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
    };
  };

  github_rev_builtin = let
    fetcher = builtins.fetchTarball;
    fetcherArgs = {
      sha256 = "1qjavxabbrsh73yck5dcq8jggvh3r2jkbr6b5nlz5d9yrqm9255n";
      url =
        "https://github.com/nmattia/niv/archive/af958e8057f345ee1aca714c1247ef3ba1c15f5e.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616819139;
      original = {
        builtin = true;
        owner = "nmattia";
        repo = "niv";
        rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
        type = "github";
      };
      rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
    };
  };

  github_rev_submodule = let
    fetcher = pkgs.fetchgit;
    fetcherArgs = {
      rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
      sha256 = "1qjavxabbrsh73yck5dcq8jggvh3r2jkbr6b5nlz5d9yrqm9255n";
      url = "https://github.com/nmattia/niv.git";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616819140;
      original = {
        owner = "nmattia";
        repo = "niv";
        rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
        submodule = true;
        type = "github";
      };
    };
  };

  github_tag = let
    fetcher = pkgs.fetchzip;
    fetcherArgs = {
      sha256 = "06ghvcsarvi32awxvgdxivaji8fsdhv46p49as8xx8whwia9d3rh";
      url =
        "https://github.com/nmattia/niv/archive/62fcf7d0859628f1834d84a7a0706ace0223c27e.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616819156;
      original = {
        owner = "nmattia";
        repo = "niv";
        tag = "v0.2.19";
        type = "github";
      };
      rev = "62fcf7d0859628f1834d84a7a0706ace0223c27e";
    };
  };
}
