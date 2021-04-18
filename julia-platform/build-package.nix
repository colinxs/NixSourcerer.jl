{ lib, writeText, buildJuliaDepot }: 

let
in
{ src, ...} @ args:

let
  juliaProjectFile = src + "/Project.toml";
  juliaManifestFile = src + "/Manifest.toml";

  juliaProject = lib.importTOML juliaProjectFile;
  inherit (juliaProject) version uuid;
  pname = juliaProject.name;

  # newDeps = juliaProject.deps // { "${pname}" = uuid; };
  newDeps = juliaProject.deps; 
  newJuliaProject = writeText "Project.toml" ''
    [deps]
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList 
      (name: uuid: "${name} = \"${uuid}\"")
      newDeps)}
  '';
in buildJuliaDepot ({ 
  inherit juliaManifestFile;
  juliaProjectFile = newJuliaProject;
  name = "${pname}-${version}";
  juliaPostUpdateHook = ''
    julia -e 'using Pkg; Pkg.develop(path="${src}")'
  '';
  allowTOMLWrites = true;

} // (builtins.removeAttrs args [
  "juliaProject" "juliaManifestFile" 
]))
