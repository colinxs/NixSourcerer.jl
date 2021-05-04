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
    # url = "path:/home/colinxs";
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
          pkgs = inputs.nixpkgs.legacyPackages."${system}";
          mur = nix-home.packages."${system}";
          julia = mur.julia-bin.latest;
          
          callArgs = pkgs // { inherit julia callPackage callPackages; };
          callPackage = pkgs.lib.callPackageWith callArgs; 
          callPackages = pkgs.lib.callPackagesWith callArgs;
          juliaPlatform = callPackages ./julia-platform {};
          
          depot = juliaPlatform.buildJuliaDepot {
            depot = import ./testenv/Depot.nix { inherit pkgs; };
          }; 

          main = pkgs.writeScriptBin "nix-sourcerer" ''
            #!/usr/bin/env nix-shell 
            #!nix-shell -i bash ${./shell.nix} --argstr system ${system} --arg home "import ${inputs.nix-home}/nix-home"
            julia --startup-file=no --compile=min -O1 --project=${./.} -e 'using Pkg; Pkg.instantiate()' 
            julia --startup-file=no --compile=min -O1 --project=${./.} ${./bin/main.jl} "$@"
          '';
          
          test = pkgs.writeScriptBin "test" ''
            #!/usr/bin/env nix-shell 
            #!nix-shell -i bash ${./shell.nix} --argstr system ${system} --arg home "import ${inputs.nix-home}/nix-home"
            julia --startup-file=no --compile=min -O1 --project=${./.} -e 'using Pkg; Pkg.instantiate()' 
            julia --startup-file=no --compile=min -O1 --project=${./.} -e 'using Pkg; Pkg.test()' 
          '';
        in rec {
          # defaultPackage = julia-wrapped;
          # packages = {
          #   inherit depot updateScript;
          #   julia = julia-wrapped;
          #   nix-sourcerer = main;
          #   inherit nix-prefetch;
          # };

          legacyPackages = {
            inherit juliaPlatform depot;
          };

          defaultApp = apps."nix-sourcerer";
          apps."nix-sourcerer" = flake-utils.lib.mkApp { drv = main; };
          apps."test" = flake-utils.lib.mkApp { drv = test; };
          # apps.julia  = flake-utils.lib.mkApp { drv = julia-wrapped; name = "julia"; };
        });
    in outputs // systemOutputs;
}


      # julia-wrapped = juliaPlatform.buildJuliaWrapper {
      #   inherit depot julia;
      #   extraPackages = with pkgs; [ git nix nix-prefetch nixpkgs-fmt ];
      #   defaultDepots = true;
      # };
        
      # nix-prefetch = pkgs.nix-prefetch.override { nix = pkgs.nixFlakes; }; 
      # updateScript = 
      #   let
      #     expr = ''
      #       {sha256}:
      #         let
      #           regs = [ ${inputs.general-registry} ${inputs.personal-registry} ];
      #           flake = (import ${inputs.flake-compat} { src = ${./.}; }).defaultNix;
      #         in
      #          flake.packages.x86_64-linux.depot.overrideAttrs (_: { sha256=${pkgs.lib.fakeSha256};  })
      #     '';
      #     in
      #     pkgs.writeScriptBin "NixSourcerer" ''
      #       #!${pkgs.stdenv.shell}
      #       ${nix-prefetch}/bin/nix-prefetch '${expr}' --hash-algo sha256 --output raw
      #     '';

      # main = pkgs.writeScriptBin "nix-sourcerer" ''
      #   #!${pkgs.stdenv.shell}
      #   ${julia-wrapped}/bin/julia --startup-file=no --compile=min -O1 ${./bin/main.jl} "$@"
      #   '';
