{
  inputs.flake-utils.url = "github:numtide/flake-utils";

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

  outputs = { self, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages."${system}";
      murpkgs = inputs.nix-home.legacyPackages."${system}".mur;
      julia = murpkgs.julia.latest;
      buildJuliaEnvironment = pkgs.callPackage ./juliaPlatform/buildJuliaEnvironment.nix { inherit julia; };
      buildJuliaDepot = pkgs.callPackage ./juliaPlatform/buildJuliaDepot.nix { inherit julia; };
      buildJuliaPackage = pkgs.callPackage ./juliaPlatform/buildJuliaPackage.nix { inherit buildJuliaEnvironment; };
      buildOverrides= pkgs.callPackage ./juliaPlatform/buildOverrides.nix { };
      
      juliaProjectFile=./testenv/Project.toml; 
      juliaManifestFile=./testenv/Manifest.toml; 
      juliaRegistries = [
        inputs.general-registry
        inputs.personal-registry
      ];

      hash = "sha256:0x5dxjkidfcs1kd1450cg4w05rgv1k1nvzjncrswdisvxsw5jh7z"; 
    in {
      defaultPackage."${system}" = buildJuliaDepot { 
        juliaProjectFile=./testenv/Project.toml; 
        juliaManifestFile=./testenv/Manifest.toml; 
        juliaPackages = import ./testenv/NixManifest.nix { inherit pkgs; };
        # sha256 = pkgs.lib.fakeSha256;
        sha256 = "0n3fhd2fa0gh6fqvfnw710ahiysjcfr80jp24rzyh0ks6wz9qrgz";
      }; 
      # defaultPackage."${system}" = buildJuliaPackage { 
      #   inherit juliaRegistries;
      #   src = ./.;
      #   sha256 = pkgs.lib.fakeSha256;
      # }; 
      # defaultPackage."${system}" = buildOverrides { 
      #   # juliaArtifactsFile = ./testenv/Artifacts.toml;
      #   juliaArtifactsFiles = [./testenv/Artifacts.toml ./testenv/Artifacts2.toml];
      #   # sha256 = pkgs.lib.fakeSha256;
      # }; 
    };
}


