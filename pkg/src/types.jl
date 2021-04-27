####
#### NixSourcererError
####

struct NixSourcererError <: Exception
    msg::String
end

nixsourcerer_error(msg::String...) = throw(NixSourcererError(join(msg)))

Base.showerror(io::IO, err::NixSourcererError) = print(io, err.msg)


####
#### Source
####

const SOURCE_KEYMAP = Dict(
    "pname" => "pname",
    "version" => "version",
    "name" => "name",
    "fetcher_name" => "fetcherName",
    "fetcher_args" => "fetcherArgs",
    "meta" => "meta"
)

mutable struct Source
    pname::String
    version::String
    name::String
    fetcher_name::String
    fetcher_args::Dict{String,Any}
    meta::Dict{String,Any}
end

function Source(;
    pname,
    version,
    name="$(pname)-$(version)",
    fetcher_name,
    fetcher_args,
    meta=Dict{String,Any}(),
)
    return Source(
        strip(pname), strip(version), strip(name), strip(fetcher_name), fetcher_args, meta
    )
end

function Nix.print(io::IO, source::Source)
    dict = Dict(
        :name => source.name,
        :pname => source.pname,
        :version => source.version,
        :fetcher => Nix.NixText(source.fetcher_name),
        :fetcherName => source.fetcher_name,
        :fetcherArgs => source.fetcher_args,
        :outPath => Nix.NixText("fetcher fetcherArgs"),
        :meta => source.meta,
    )
    write(io, "let ")
    for pair in dict
        Nix.print(io, pair)
    end
    write(io, "in { inherit ")
    for var in keys(dict)
        write(io, ' ')
        Nix.print(io, var)
    end
    return write(io, "; }")
end

####
#### Schemas
####

abstract type Schema end

struct SimpleSchema <: Schema
    key::String
    type::Type
    required::Bool
end

Base.keys(schema::SimpleSchema) = (schema.key,)

function validate(schema::SimpleSchema, spec)
    key = schema.key
    if haskey(spec, key)
        T = schema.type
        V = typeof(spec[key])
        if !(V <: T)
            nixsourcerer_error("Expected key \"$key\" to be of type $T, got $V")
        end
    elseif schema.required
        nixsourcerer_error("Must specify \"$key\"")
    end
end

struct ExclusiveSchema{N} <: Schema
    keys::NTuple{N,String}
    types::NTuple{N,DataType}
    required::Bool
end

Base.keys(schema::ExclusiveSchema) = schema.keys

function validate(schema::ExclusiveSchema, spec)
    idx = findfirst(k -> haskey(spec, k), schema.keys)
    if idx !== nothing
        key = schema.keys[idx]
        T = schema.types[idx]
        V = typeof(spec[key])
        if !(V <: T)
            nixsourcerer_error("Expected key \"$key\" to be of type $T, got $V.")
        end
    elseif schema.required
        nixsourcerer_error("Must specify exactly one of \"$(schema.keys)\".")
    end
end

struct SchemaSet{N} <: Schema
    schemas::NTuple{N,Schema}
end

SchemaSet(schemas::Schema...) = SchemaSet(schemas)

Base.keys(schema::SchemaSet) = foldl((a, b) -> (a..., keys(b)...), schema.schemas; init=())

const DEFAULT_SCHEMA_SET = SchemaSet(
    SimpleSchema("type", String, true),
    SimpleSchema("builtin", Bool, false),
    SimpleSchema("meta", Dict, false),
)

function validate(set::SchemaSet, spec)
    augmented = SchemaSet(DEFAULT_SCHEMA_SET.schemas..., set.schemas...)
    check_unknown_keys(augmented, spec)
    for schema in augmented.schemas
        validate(schema, spec)
    end
end

function check_unknown_keys(set::SchemaSet, spec)
    unknown = setdiff(keys(spec), keys(set))
    if length(unknown) > 0
        nixsourcerer_error("Unknown key(s): $(Tuple(unknown))")
    end
end

####
#### Project
####

# TODO it's weird that manifest is .meta but project is dict

const PROJECT_FILE_NAME = "NixProject.toml"

struct Project
    specs::Dict{String,Any}
end

Project() = Project(Dict{String,Any}())

function validate(project::Project)
    for (name, spec) in project.specs
        try
            if !haskey(spec, "type")
                nixsourcerer_error("\"type\" not specified")
            elseif !haskey(SCHEMAS, spec["type"])
                nixsourcerer_error("Unknown type \"$(spec["type"])\"")
            else
                validate(SCHEMAS[spec["type"]], spec)
            end
        catch e
            nixsourcerer_error("Could not parse spec \"$name\": ", sprint(showerror, e))
            rethrow()
        end
    end
end

has_project(dir::AbstractString) = isfile(joinpath(dir, PROJECT_FILE_NAME))

function read_project(project_file::AbstractString=PROJECT_FILE_NAME)
    raw = TOML.parsefile(project_file)
    # TODO hack
    for v in values(raw)
        v["meta"] = get(v, "meta", Dict())
    end
    return Project(raw)
end

function write_project(project::Project, project_file::AbstractString=PROJECT_FILE_NAME)
    open(project_file, "w") do io
        TOML.print(io, project.specs)
    end
end

####
#### Manifest
####

const MANIFEST_FILE_NAME = "NixManifest.nix"

struct Manifest
    sources::Dict{String,Source}
end

Manifest() = Manifest(Dict{String,Source}())

function validate(manifest::Manifest) end

has_manifest(dir::AbstractString) = isfile(joinpath(dir, MANIFEST_FILE_NAME))

function read_manifest(manifest_file::AbstractString=MANIFEST_FILE_NAME)
    manifest_file = abspath(manifest_file)
    fields = ["pname", "version", "name", "fetcherName", "fetcherArgs", "meta"]
    expr = """
        with builtins; 
        let
            fields = [$(join(map(s -> "\"$(s)\"", fields), ' '))];
            getFields = _: v: foldl' (a: b: a // b) {} (map (n: { "\${n}" = v."\${n}"; }) fields);
        in
        mapAttrs getFields (import "$(manifest_file)" {})
    """
    raw = strip(read(`nix eval --json "($expr)"`, String))
    json = JSON.parse(raw)

    manifest = Manifest()
    for (name, source) in json
        args = [source[k] for k in fields] 
        manifest.sources[name] = Source(args...)
    end

    return manifest
end


function write_manifest(manifest::Manifest, manifest_file::AbstractString=MANIFEST_FILE_NAME)
    io = IOBuffer(; append=true)
    write(io, "{ pkgs ? import <nixpkgs> {} }:")
    Nix.print(io, manifest.sources; sort = true)
    open(manifest_file, "w") do f
        Nix.format(f, io)
    end
end

####
#### Package
####

mutable struct Package
    project::Project
    manifest::Manifest
    project_file::String
    manifest_file::String
end

function validate(package::Package)
    validate(package.project)
    return validate(package.manifest)
end

function read_package(dir::AbstractString)
    project_file = joinpath(dir, PROJECT_FILE_NAME)
    manifest_file = joinpath(dir, MANIFEST_FILE_NAME)
    manifest = isfile(manifest_file) ? read_manifest(manifest_file) : Manifest()
    return Package(read_project(project_file), manifest, project_file, manifest_file)
end

function write_package(package::Package)
    # TODO sort keys?
    # write_project(package.project, package.project_file)
    for name in keys(package.manifest.sources)
        if !haskey(package.project.specs, name)
            delete!(package.manifest.sources, name)
        end
    end
    return write_manifest(package.manifest, package.manifest_file)
end
