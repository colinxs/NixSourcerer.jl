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
    url = "git+ssh://git@github.com/colinxs/home?ref=flake&dir=nix-home";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, nixpkgs, nix-home, ... }@inputs: 
    flake-utils.lib.eachSystem ["x86_64-linux"] (system:
    let
      name = "NixSourcerer";
      pkgs = nixpkgs.legacyPackages."${system}";
      murpkgs = nix-home.legacyPackages."${system}".mur;
      julia = murpkgs.julia.latest;

      callPackage = pkgs.lib.callPackageWith ( pkgs // { inherit julia callPackage; } );
      juliaPlatform = callPackage ./julia-platform {};
      
      depot = juliaPlatform.buildJuliaPackage { 
        src = ./.;
        # src = builtins.path { path=./.; filter = (p: t: p == ./Project.toml); };
        # src = pkgs.lib.sourceByRegex ./. [ 
        #   "^Project.toml$"
        #   "^Manifest.toml$"
        #   "^src"
        # ];

        juliaRegistries = with inputs; [ general-registry personal-registry ];
        # sha256 = "1vbf4k5nck4wl73m09p6mbpr0f8rvkbcs21s02h3r9d07wsfwfx7";
        sha256 = pkgs.lib.fakeSha256;
      }; 
      # depot = juliaPlatform.buildJuliaDepot { 
      #   juliaProjectFile = ./testenv/Project.toml;
      #   juliaManifestFile = ./testenv/Manifest.toml;
      #   juliaRegistries = with inputs; [ general-registry personal-registry ];
      #   # sha256 = "1vbf4k5nck4wl73m09p6mbpr0f8rvkbcs21s02h3r9d07wsfwfx7";
      #   sha256 = pkgs.lib.fakeSha256;
      # }; 
      
      
      # depot = juliaPlatform.buildJuliaPackage { 
      #   src = ./testenv;
      #   juliaRegistries = with inputs; [ general-registry personal-registry ];
      #   # sha256 = "1vbf4k5nck4wl73m09p6mbpr0f8rvkbcs21s02h3r9d07wsfwfx7";
      #   sha256 = pkgs.lib.fakeSha256;
      # }; 

      julia-wrapped = juliaPlatform.buildJuliaWrapper {
        inherit depot julia;
        extraPackages = with pkgs; [ git nix nix-prefetch nixpkgs-fmt ];
        defaultDepots = true;
      };

      main = pkgs.writeScriptBin "nix-sourcerer" ''
        #!${pkgs.stdenv.shell}
        ${julia}/bin/julia --startup-file=no --compile=min -O1 ${./bin/main.jl} "$@"
      '';

      updateScript = 
        let
          nix-prefetch = pkgs.nix-prefetch.override { nix = pkgs.nixFlakes; }; 
          expr = ''
            {sha256}:
              let
                regs = [ ${inputs.general-registry} ${inputs.personal-registry} ];
                flake = (import ${inputs.flake-compat} { src = ${./.}; }).defaultNix;
              in
               flake.packages.x86_64-linux.depot.overrideAttrs (_: { sha256=${pkgs.lib.fakeSha256};  })
          '';
          in
          pkgs.writeScriptBin "update" ''
            #!${pkgs.stdenv.shell}
            ${nix-prefetch}/bin/nix-prefetch '${expr}' --hash-algo sha256 --output raw
          '';
    in rec {
      packages = {
        inherit depot updateScript;
        julia = julia-wrapped;
        nix-sourcerer = main;
      };
      defaultPackage = julia-wrapped;
      apps."${name}" = flake-utils.lib.mkApp { drv = main; };
      defaultApp = apps."${name}";
    });
}


