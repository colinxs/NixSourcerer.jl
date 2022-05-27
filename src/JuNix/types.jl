# Similar to Pkg.Types.GitRepo
Base.@kwdef struct RepoInfo 
    url::String
    rev::String
    subdir::Union{String,Nothing}
end

Base.@kwdef mutable struct PackageInfo
    name::String
    uuid::UUID
    version::Union{Nothing,VersionNumber}
    tree_hash::SHA1
    source::String

    is_tracking_path::Bool
    is_tracking_repo::Bool
    is_tracking_registry::Bool

    registries::Vector{RegistrySpec} = RegistrySpec[]
    repos::Vector{RepoInfo} = RepoInfo[]
    artifacts::Vector{ArtifactInfo} = ArtifactInfo[]
    archives::Vector{String} = String[]
end

# Same as Pkg.API.PackageInfo but with extra fields
Base.@kwdef struct PackageInfo
    name::String
    version::Union{Nothing,VersionNumber}
    tree_hash::Union{Nothing,String}
    is_direct_dep::Bool
    is_pinned::Bool
    is_tracking_path::Bool
    is_tracking_repo::Bool
    is_tracking_registry::Bool
    git_revision::Union{Nothing,String}
    git_source::Union{Nothing,String}
    source::String
    dependencies::Dict{String,UUID}

    # extra fields
    repos = 
end

Base.@kwdef mutable struct PackageInfo
    name::String
    uuid::UUID
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
end


Base.@kwdef struct Options
    nworkers::Int = 1
    arch::Union{Set{String},Nothing} = nothing
    os::Union{Set{String},Nothing} = nothing
    libc::Union{Set{String},Nothing} = nothing
    lazy_artifacts::Bool = false
    pkg_server::Union{String,Nothing} = pkg_server()
    force_overwrite::Bool = false
    check_store::Bool = false
end
