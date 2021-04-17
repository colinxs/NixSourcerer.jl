{ lib, writeText, buildJuliaEnvironment }: 

let
in
{ src, ...} @ args:

let
  juliaProjectFile = src + "/Project.toml";
  juliaManifestFile = src + "/Manifest.toml";

  juliaProject = lib.importTOML juliaProjectFile;
  inherit (juliaProject) version uuid;
  pname = juliaProject.name;

  newDeps = juliaProject.deps // { "${pname}" = uuid; };
  newJuliaProject = writeText "Project.toml" ''
    [deps]
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList 
      (name: uuid: "${name} = \"${uuid}\"")
      newDeps)}
  '';
in buildJuliaEnvironment ({ 
  inherit juliaManifestFile;
  juliaProjectFile = newJuliaProject;
  name = "${pname}-${version}";
  juliaUpdateHook = ''
    julia -e 'using Pkg; Pkg.resolve()'
  '';
  allowTOMLWrites = true;

} // (builtins.removeAttrs args [
  "juliaProject" "juliaManifestFile" 
]))
