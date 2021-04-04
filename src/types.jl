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
    name = "$(pname)-$(version)",
    fetcher,
    fetcher_args,
    meta = Dict{String,Any}()
)
    return Source(
        strip(pname),
        strip(version),
        strip(name),
        strip(fetcher),
        fetcher_args,
        meta
    )
end

function Nix.print(io::IO, source::Source)
    write(io, "let ")
    Nix.print(io, Pair(:name, source.name))
    Nix.print(io, Pair(:pname, source.pname))
    Nix.print(io, Pair(:version, source.version))
    Nix.print(io, Pair(:fetcher, Nix.NixText(source.fetcher)))
    Nix.print(io, Pair(:fetcherName, source.fetcher))
    Nix.print(io, Pair(:fetcherArgs, source.fetcher_args))
    Nix.print(io, Pair(:src, Nix.NixText("fetcher fetcherArgs")))
    Nix.print(io, Pair(:meta, source.meta))
    write(io, "in")
    write(io, "{ inherit name pname version fetcher fetcherName fetcherArgs meta; }")
    return nothing
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

function validate(schema::SimpleSchema, source)
    key = schema.key
    if haskey(source, key)
        T = schema.type
        V = typeof(source[key])
        if ! (V <: T )
            nixsourcerer_nixsourcerer_error("Expected key \"$key\" to be of type $T, got $V") 
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

function validate(schema::ExclusiveSchema, source)
    idx = findfirst(k -> haskey(source, k), schema.keys)
    if idx !== nothing
        key = schema.keys[idx]
        T = schema.types[idx]
        V = typeof(source[key])
        if ! (V <: T)
            nixsourcerer_error("Expected key \"$key\" to be of type $T, got $V")
        end
    elseif schema.required
        nixsourcerer_error("Must specify exactly one of \"$(schema.keys)\"")
    end
end


struct CompositeSchema <: Schema
    schemas::Vector{Schema}
end

CompositeSchema(schemas::Schema...) = CompositeSchema(collect(schemas))

function validate(schema::CompositeSchema, spec)
    all_keys = Set{String}()
    for schema in schema.schemas
        validate(schema, spec)
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
            nixsourcerer_error("Could not parse source \"$name\"", sprint(showerror, e))
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
####project.jl

const MANIFEST_FILE_NAME = "NixManifest.nix"

struct Manifest
    sources::Dict{String,Source}
end

Manifest() = Manifest(Dict{String,Source}())

function validate(manifest::Manifest)
end

has_manifest(dir::AbstractString) = isfile(joinpath(dir, MANIFEST_FILE_NAME))

function write_manifest(manifest::Manifest, manifest_file::AbstractString)
    io = IOBuffer(append=true) 
    write(io, "{ pkgs ? import <nixpkgs> {} }:")
    Nix.print(io, manifest.sources)
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
    validate(package.manifest)
end

function read_package(dir::AbstractString)
    project_file = joinpath(dir, PROJECT_FILE_NAME)
    manifest_file = joinpath(dir, MANIFEST_FILE_NAME)
    Package(
        read_project(project_file),
        Manifest(),
        project_file,
        manifest_file
    )
end

function write_package(package::Package) 
    write_manifest(package.manifest, package.manifest_file)
    # write_project(package.project, package.project_file)
end



