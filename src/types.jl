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

struct Source
    pname::String
    version::String
    name::String
    fetcher::String
    fetcher_args::Dict{String,Any}
    meta::Dict{String,Any}
end

function Source(;
    pname,
    version,
    name="$(pname)-$(version)",
    fetcher,
    fetcher_args,
    meta=Dict{String,Any}(),
)
    return Source(
        strip(pname), strip(version), strip(name), strip(fetcher), fetcher_args, meta
    )
end

function Nix.print(io::IO, source::Source)
    dict = Dict(
        :name => source.name,
        :pname => source.pname,
        :version => source.version,
        :fetcher => Nix.NixText(source.fetcher),
        :fetcherName => source.fetcher,
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

function validate(schema::SimpleSchema, source)
    key = schema.key
    if haskey(source, key)
        T = schema.type
        V = typeof(source[key])
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

function validate(schema::ExclusiveSchema, source)
    idx = findfirst(k -> haskey(source, k), schema.keys)
    if idx !== nothing
        key = schema.keys[idx]
        T = schema.types[idx]
        V = typeof(source[key])
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

function validate(set::SchemaSet, source)
    augmented = SchemaSet(DEFAULT_SCHEMA_SET.schemas..., set.schemas...)
    check_unknown_keys(augmented, source)
    for schema in augmented.schemas
        validate(schema, source)
    end
end

function check_unknown_keys(set::SchemaSet, source)
    unknown = setdiff(keys(source), keys(set))
    if length(unknown) > 0
        nixsourcerer_error("Unknown key(s): $(Tuple(unknown))")
    end
end

####
#### Project
####

const PROJECT_FILE_NAME = "NixProject.toml"

struct Project
    sources::Dict{String,Any}
end

Project() = Project(Dict{String,Any}())

function validate(project::Project)
    for (name, source) in project.sources
        try
            if !haskey(source, "type")
                nixsourcerer_error("\"type\" not specified")
            elseif !haskey(SCHEMAS, source["type"])
                nixsourcerer_error("Unknown type \"$(source["type"])\"")
            else
                validate(SCHEMAS[source["type"]], source)
            end
        catch e
            nixsourcerer_error("Could not parse source \"$name\": ", sprint(showerror, e))
            rethrow()
        end
    end
end

has_project(dir::AbstractString) = isfile(joinpath(dir, PROJECT_FILE_NAME))

function read_project(project_file::AbstractString)
    return Project(TOML.parsefile(project_file))
end

function write_project(project::Project, project_file::AbstractString)
    open(project_file, "w") do io
        TOML.print(io, Project.sources)
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

function write_manifest(manifest::Manifest, manifest_file::AbstractString)
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
    return Package(read_project(project_file), Manifest(), project_file, manifest_file)
end

function write_package(package::Package)
    # TODO sort keys?
    # write_project(package.project, package.project_file)
    return write_manifest(package.manifest, package.manifest_file)
end
