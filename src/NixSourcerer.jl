# TODO delete unneeded stuff
# TODO bootstrap nixpkgs
# TODO make manifest read data from project rather than copying over info?

module NixSourcerer

using Base
using TOML
using JSON
using HTTP
using Git
using Dates
using ArgParse
using Pkg
using Random
using URIs
using Printf
using SHA

Base.include(@__MODULE__, joinpath(Sys.BINDIR, "..", "share", "julia", "test", "testhelpers", "FakePTYs.jl"))
using .FakePTYs: open_fake_pty

export update
export update_package
export Nix

const NO_HASH_FETCHERS = (
    "builtins.fetchGit",
)

include("Nix.jl")
using .Nix

include("types.jl")
include("util.jl")

include("handlers/git.jl")
include("handlers/github.jl")
include("handlers/file.jl")
include("handlers/archive.jl")
include("handlers/crate.jl")

include("update.jl")
include("main.jl")

const SCHEMAS = Dict(
    "github" => GITHUB_SCHEMA,
    "file" => FILE_SCHEMA,
    "archive" => ARCHIVE_SCHEMA,
    "crate" => CRATE_SCHEMA,
    "git" => GIT_SCHEMA,
)

const HANDLERS = Dict(
    "github" => github_handler,
    "file" => file_handler,
    "archive" => archive_handler,
    "crate" => crate_handler,
    "git" => git_handler,
)

function __init__()
    try
        # We don't want overlays or anything else as it breaks
        # nix-prefetch
        nixpath = get(ENV, "NIX_PATH", nothing)
        nixpath === nothing && nixsourcerer_error("NIX_PATH is empty!")
        entries = filter(split(nixpath, ':')) do entry
            name, path = split(entry, '=')
            name == "nixpkgs"
        end
        ENV["NIX_PATH"] = only(entries)
        return nothing
    catch e
        Base.@warn "Failed to initialize the environment" exception = (e, catch_backtrace())
    end
end


const DEFAULT_NIX = joinpath(@__DIR__, "../../default.nix")

end # module
