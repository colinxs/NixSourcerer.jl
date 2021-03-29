{ pkgs ? import <nixpkgs> { } }: {
  archive_builtin = let
    fetcher = builtins.fetchTarball;
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992412;
      original = {
        builtin = true;
        type = "archive";
        url =
          "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
      };
    };
  };

  archive_nixpkgs = let
    fetcher = pkgs.fetchzip;
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992414;
      original = {
        type = "archive";
        url =
          "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
      };
    };
  };

  crate_latest_builtin = let
    fetcher = builtins.fetchTarball;
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992412;
      original = {
        builtin = true;
        pname = "lscolors";
        type = "crate";
        version = "latest";
      };
      version = "0.7.1";
    };
  };

  crate_latest_nixpkgs = let
    fetcher = pkgs.fetchzip;
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992440;
      original = {
        pname = "lscolors";
        type = "crate";
        version = "latest";
      };
      version = "0.7.1";
    };
  };

  crate_stable_builtin = let
    fetcher = builtins.fetchTarball;
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992412;
      original = {
        builtin = true;
        pname = "lscolors";
        type = "crate";
        version = "stable";
      };
      version = "0.7.1";
    };
  };

  crate_stable_nixpkgs = let
    fetcher = pkgs.fetchzip;
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992435;
      original = {
        pname = "lscolors";
        type = "crate";
        version = "stable";
      };
      version = "0.7.1";
    };
  };

  crate_version_builtin = let
    fetcher = builtins.fetchTarball;
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992412;
      original = {
        builtin = true;
        pname = "lscolors";
        type = "crate";
        version = "0.7.1";
      };
      version = "0.7.1";
    };
  };

  crate_version_nixpkgs = let
    fetcher = pkgs.fetchzip;
    fetcherArgs = {
      sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
      url =
        "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992430;
      original = {
        pname = "lscolors";
        type = "crate";
        version = "0.7.1";
      };
      version = "0.7.1";
    };
  };

  file = let
    fetcher = pkgs.fetchurl;
    fetcherArgs = {
      sha256 = "011srzqjv4wrman6nsp3d190b2vcsmn8jnw64aksk0q0xb26ld6j";
      url = "https://julialang-s3.julialang.org/bin/versions.json";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992414;
      original = {
        type = "file";
        url = "https://julialang-s3.julialang.org/bin/versions.json";
      };
    };
  };

  git_branch = let
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
      lastChecked = 1616992425;
      original = {
        branch = "master";
        type = "git";
        url = "https://github.com/nmattia/niv.git";
      };
    };
  };

  git_builtin = let
    fetcher = builtins.fetchGit;
    fetcherArgs = {
      ref = "refs/heads/master";
      rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
      url = "https://github.com/nmattia/niv.git";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992410;
      original = {
        branch = "master";
        builtin = true;
        type = "git";
        url = "https://github.com/nmattia/niv.git";
      };
    };
  };

  git_rev = let
    fetcher = pkgs.fetchgit;
    fetcherArgs = {
      rev = "62fcf7d0859628f1834d84a7a0706ace0223c27e";
      sha256 = "06ghvcsarvi32awxvgdxivaji8fsdhv46p49as8xx8whwia9d3rh";
      url = "https://github.com/nmattia/niv.git";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992414;
      original = {
        rev = "62fcf7d0859628f1834d84a7a0706ace0223c27e";
        type = "git";
        url = "https://github.com/nmattia/niv.git";
      };
    };
  };

  git_submodule = let
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
      lastChecked = 1616992419;
      original = {
        branch = "master";
        submodule = true;
        type = "git";
        url = "https://github.com/nmattia/niv.git";
      };
    };
  };

  git_tag = let
    fetcher = pkgs.fetchgit;
    fetcherArgs = {
      rev = "62fcf7d0859628f1834d84a7a0706ace0223c27e";
      sha256 = "06ghvcsarvi32awxvgdxivaji8fsdhv46p49as8xx8whwia9d3rh";
      url = "https://github.com/nmattia/niv.git";
    };
  in {
    inherit fetcher fetcherArgs;
    src = fetcher fetcherArgs;
    meta = {
      lastChecked = 1616992422;
      original = {
        tag = "v0.2.19";
        type = "git";
        url = "https://github.com/nmattia/niv.git";
      };
    };
  };

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
      lastChecked = 1616992445;
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
      lastChecked = 1616992425;
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
      lastChecked = 1616992419;
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
      lastChecked = 1616992412;
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
      lastChecked = 1616992414;
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
      lastChecked = 1616992450;
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
