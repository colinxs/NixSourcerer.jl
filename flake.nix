{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  inputs.general-registry = {
    url = "github:JuliaRegistries/General";
    flake = false;
  };
  
  inputs.personal-registry = {
    url = "github:colinxs/JuliaRegistry";
    flake = false;
  };
  
  inputs.nix-home = {
    # url = "path:/home/colinxs/nix-home";
    # url = "git+ssh://git@github.com/colinxs/home?dir=nix-home";
    url = github:colinxs/home?dir=nix-home;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, nix-home, ... }@inputs:
    let
      name = "NixSourcerer";
      outputs = {};
      systemOutputs = flake-utils.lib.eachSystem ["x86_64-linux"] (system:
        let
          pkgs = import inputs.nixpkgs { inherit system; inherit (self) overlay; };
          mur = nix-home.packages."${system}";
          dev = mur.dev;
          julia = mur.julia-bin.latest;
          juliaPlatform = mur.juliaPlatform;

          julia-wrapped = juliaPlatform.mkJuliaWrapper {
            defaultDepots = true;
            startupFile = false;
            historyFile=false;
            color = true;
            compile = "min";
            optLevel = 1;

            activeProject = ./.;

            disableRegistryUpdate = true;
            instantiate = true;
            extraPackages = with pkgs; [ nix nix-prefetch nixpkgs-fmt nixfmt  ];
          };
            
          nix-sourcerer = dev.writeShellScriptBin "nix-sourcerer" {} ''
            exec ${julia-wrapped}/bin/julia ${./bin/main.jl} "$@"
          '';
          
          run-test = dev.writeShellScriptBin "test" {} ''
            exec ${julia-wrapped}/bin/julia -e 'using Pkg; Pkg.test()'
          '';
        in rec {
          legacyPackages = {
            inherit julia-wrapped nix-sourcerer run-test;
          };

          defaultApp = apps."nix-sourcerer";
          apps."nix-sourcerer" = flake-utils.lib.mkApp { drv = nix-sourcerer; };
          apps."run-test" = flake-utils.lib.mkApp { drv = run-test; };
          apps.julia  = flake-utils.lib.mkApp { drv = julia-wrapped; name = "julia"; };
          
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
    in outputs // systemOutputs;
}
