{
  inputs.nix-home.url = "path:/home/colinxs/nix-home";
  # inputs.nix-home.url = "git+ssh://git@github.com/colinxs/home?dir=nix-home";

  inputs.nixpkgs.follows = "nix-home/nixpkgs";

  inputs.flake-utils.follows = "nix-home/flake-utils";
  
  inputs.flake-compat.follows = "nix-home/flake-compat";

  outputs = { self, nix-home, nixpkgs, flake-utils, ... }@inputs:
    let
      name = "NixSourcerer";
      outputs = { };
      systemOutputs = flake-utils.lib.eachSystem nix-home.lib.defaultPlatforms (system:
        let
          # pkgs = import inputs.nixpkgs { inherit system; inherit (self) overlay; };
          # mur = nix-home.legacyPackages."${system}".mur;
         
          dev = nix-home.lib;
          pkgs = nix-home.legacyPackages."${system}";
          inherit (pkgs) mur;
          inherit (mur) julia buildJuliaApplication;

          julia-wrapped = mur.mkWrapper {
            package = mur.julia-bin-latest;
            wrapper = {
              program = "julia";
              extraPackages = with pkgs; [
                nix
                nixpkgs-fmt
                nix-prefetch
              ];
              # setEnv.NIX_PATH = "nixpkgs=${(builtins.getFlake (toString ./.).
              setEnv.NIX_PATH = "nixpkgs=${nixpkgs.outPath}";
              args = [ 
                "--project=${./.}"
                "--startup-file=no"
                "--history-file=no"
                "--color=yes"
                "--compile=min"
                "-O1"
              ];
            };
          };

          nix-sourcerer = mur.writeShellScriptBin "nix-sourcerer" { } ''
            set -ex
            ${julia-wrapped}/bin/julia -e 'using Pkg; Pkg.instantiate()' \
            && exec ${julia-wrapped}/bin/julia ${./bin/main.jl} "$@"
          '';

          run-test = mur.writeShellScriptBin "test" { } ''
            ${julia-wrapped}/bin/julia -e 'using Pkg; Pkg.instantiate()' \
            && exec ${julia-wrapped}/bin/julia -e 'using Pkg; Pkg.test()'
          '';
        in
        rec {
          legacyPackages = {
            inherit pkgs julia-wrapped nix-sourcerer run-test;
          };

          apps.default = apps."nix-sourcerer";
          apps."nix-sourcerer" = flake-utils.lib.mkApp { drv = nix-sourcerer; };
          apps."run-test" = flake-utils.lib.mkApp { drv = run-test; };
          apps.julia = flake-utils.lib.mkApp { drv = julia-wrapped; name = "julia"; };

          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              julia-wrapped
              nix
              nix-prefetch
              nixpkgs-fmt
              cacert # Needed for network access
            ];
          };
        });
    in
    outputs // systemOutputs;
}

