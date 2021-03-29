{ fetchurl, fetchzip, fetchCrate, fetchFromGitHub }: {
  julia-versions = fetchurl {
    name = "julia-versions";
    sha256 = "11h2kawf4vmrfmp6i3cprsr3qbp7fwaivs8ibnisqsfdxgg7aq63";
    url = "https://julialang-s3.julialang.org/bin/versions.json";
  };
  lscolors_crate = fetchCrate {
    name = "lscolors_crate";
    pname = "lscolors";
    sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
    version = "0.7.1";
  };
  lscolors_url = fetchzip {
    name = "lscolors_url";
    sha256 = "1kli299gg3vafjj0vbrfmwcaawq23c9dw31q25i2g3n49pyfic62";
    url = "https://crates.io/api/v1/crates/lscolors/0.7.1/download#crate.tar.gz";
  };
  niv_branch = fetchFromGitHub {
    name = "niv_branch";
    owner = "nmattia";
    repo = "niv";
    rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
    sha256 = "1qjavxabbrsh73yck5dcq8jggvh3r2jkbr6b5nlz5d9yrqm9255n";
  };
  niv_commit = fetchFromGitHub {
    fetchSubmodules = true;
    name = "niv_commit";
    owner = "nmattia";
    repo = "niv";
    rev = "af958e8057f345ee1aca714c1247ef3ba1c15f5e";
    sha256 = "1qjavxabbrsh73yck5dcq8jggvh3r2jkbr6b5nlz5d9yrqm9255n";
  };
  niv_tag = fetchFromGitHub {
    name = "niv_tag";
    owner = "nmattia";
    repo = "niv";
    rev = "62fcf7d0859628f1834d84a7a0706ace0223c27e";
    sha256 = "06ghvcsarvi32awxvgdxivaji8fsdhv46p49as8xx8whwia9d3rh";
  };
  tree-sitter-bash_release = fetchFromGitHub {
    name = "tree-sitter-bash_release";
    owner = "tree-sitter";
    repo = "tree-sitter-bash";
    rev = "df0f7bcd72c2a6632f8a15c0ba88972ec5e96878";
    sha256 = "18c030bb65r50i6z37iy7jb9z9i8i36y7b08dbc9bchdifqsijs5";
  };
}
