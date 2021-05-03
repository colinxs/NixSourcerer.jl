struct Fetcher
    name::String
    args::Dict{String,Any}
end

function Base.show(io::IO, fetcher::M.Fetcher)
    print(io, fetcher.name)
    for (k, v) in fetcher.args
        print(io, " --", k, " ", v)
    end
    return nothing
end

function Nix.print(io::IO, fetcher::Fetcher)
    print(io, '(')
    print(io, fetcher.name, " ")
    Nix.print(io, fetcher.args)
    print(io, ')')
    return nothing
end


Base.@kwdef mutable struct ArtifactInfo
    name::String
    tree_hash::SHA1
    path::String = "artifacts/$tree_hash"
    arch::Union{String,Nothing} = nothing
    os::Union{String,Nothing} = nothing
    libc::Union{String,Nothing} = nothing
    lazy::Bool = false
    downloads::Vector{NamedTuple{(:url, :sha256), Tuple{Int64, Int64}}} = []
    fetcher::Union{Fetcher,Nothing} = nothing 
end


Base.@kwdef mutable struct PackageInfo
    uuid::UUID
    name::String
    version::VersionNumber
    tree_hash::SHA1
    depot::String
    path::String
    is_tracking_path::Bool
    is_tracking_repo::Bool
    is_tracking_registry::Bool
    registries::Vector{RegistrySpec} = RegistrySpec[]
    artifacts::Dict{String,Vector{ArtifactInfo}} = Dict{String,Vector{ArtifactInfo}}()
    repos::Vector{String} = String[]
    archives::Vector{String} = String[]
    fetcher::Union{Fetcher,Nothing} = nothing 
end


Base.@kwdef struct Options
    nworkers::Int = 1
    arch::Union{Set{String},Nothing} = nothing
    os::Union{Set{String},Nothing} = nothing
    libc::Union{Set{String},Nothing} = nothing
    lazy_artifacts::Bool = false
    pkg_server::Union{String,Nothing} = pkg_server()
end

gen_name(pkg::PackageInfo) = "$(pkg.name)-$(pkg.version)"


