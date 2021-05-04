using Pkg
using Pkg.Operations
using Pkg.Types

Pkg.activate(joinpath(@__DIR__, "testenv"))
using Pkg.Operations:
    up_load_manifest_info!,
    up_load_versions!,
    manifest_info,
    check_registered,
    load_direct_deps,
    resolve_versions!,
    update_manifest!,
    load_urls,
    tracking_registered_version,
    pkg_server

const URLS = []
Pkg.Operations.eval(
    quote
        function install_archive(
            urls::Vector{Pair{String,Bool}}, hash::SHA1, version_path::String
        )
            push!(Main.URLS, (; urls, hash, version_path))
            return false
        end
    end,
)

const GIT = []
Pkg.Operations.eval(
    quote
        function install_git(
            ctx::Context,
            uuid::UUID,
            name::String,
            hash::SHA1,
            urls::Vector{String},
            version::Union{VersionNumber,Nothing},
            version_path::String,
        )::Nothing
            push!(Main.GIT, (; uuid, name, hash, urls, version, version_path))
            # to avoid error in caller
            mkpath(version_path)
            return nothing
        end
    end,
)

@assert length(methods(Pkg.Operations.install_archive)) == 1
@assert length(methods(Pkg.Operations.install_git)) == 1

Pkg.instantiate()
