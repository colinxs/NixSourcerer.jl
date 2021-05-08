{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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
      outputs = {
        overlay = _: prev: { 
          # TODO use pkgs from final/prev? 
          inherit (systemOutputs.legacyPackages."${prev.system}") juliaPlatform; 
        };
        overlays = { juliaPlatform = outputs.overlay; };
      };
      systemOutputs = flake-utils.lib.eachSystem ["x86_64-linux"] (system:
        let
          pkgs = import inputs.nixpkgs { inherit system; inherit (self) overlay; };
          mur = nix-home.packages."${system}";
          dev = mur.dev;
          julia = mur.julia-bin.latest;
          
          callArgs = pkgs // { inherit dev julia callPackage callPackages; };
          callPackage = pkgs.lib.callPackageWith callArgs; 
          callPackages = pkgs.lib.callPackagesWith callArgs;


          juliaPlatform = callPackages ./julia-platform {};

          julia-wrapped = juliaPlatform.buildJuliaWrapper {
            defaultDepots = true;
            activeProject = ./.;
            extraWrapperArgs = {
              args = [ "--compile=min" "-O1" ];
            };
            extraPackages = with pkgs; [
              nix
              nix-prefetch
              nixpkgs-fmt
              nixfmt 
            ];
          };
          
          depot = juliaPlatform.buildJuliaDepot {
            depot = import ./Depot.nix { pkgs = (pkgs // { inherit juliaPlatform; }); };
          }; 
            
          main = pkgs.writeScriptBin "nix-sourcerer" ''
            #!${pkgs.stdenv.shell}
            exec ${julia-wrapped}/bin/julia ${./bin/main.jl} "$@"
          '';
          
          test = pkgs.writeScriptBin "test" ''
            #!${pkgs.stdenv.shell}
            exec ${julia-wrapped}/bin/julia -e 'using Pkg; Pkg.test()' 
          '';
        in rec {
          legacyPackages = {
            inherit julia-wrapped juliaPlatform depot;
          };

          defaultApp = apps."nix-sourcerer";
          apps."nix-sourcerer" = flake-utils.lib.mkApp { drv = main; };
          apps."test" = flake-utils.lib.mkApp { drv = test; };
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
