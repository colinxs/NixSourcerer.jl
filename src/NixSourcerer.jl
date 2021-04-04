module NixSourcerer

# TODO make shebang into template
# TODO suppress stderror from nix-prefetch
# TODO include name in fetcher request?
# TODO passthru extra arguments to fetcher?
# TODO change TOML sort so type first
# TODO SRI hash (https://github.com/Mic92/nix-update/blob/e21c7830824e097611d046d5d5c7bdcce124a50f/nix_update/update.py#L33)
# TODO bootstrap nixpkgs
# TODO validate schema
# TODO verify before download

using Base
using TOML
using JSON
using HTTP
using GitCommand
using Dates
using ArgParse


export update

include("Nix.jl")
using .Nix

include("types.jl")
include("schema.jl")
include("util.jl")

include("handlers/git.jl")
include("handlers/github.jl")
include("handlers/file.jl")
include("handlers/archive.jl")
include("handlers/crate.jl")

include("update.jl")
include("main.jl")

# struct Source
#     name::String
#     fetcher::String
#     fetcher_args::Dict{String,Any}
# end

const SCHEMAS = Dict(
    "github" => GITHUB_SCHEMA,
    "file" => FILE_SCHEMA,
    "archive" => ARCHIVE_SCHEMA,
    "crate" => CRATE_SCHEMA,
    "git" => GIT_SCHEMA
)

const HANDLERS = Dict(
    "github" => github_handler,
    "file" => file_handler,
    "archive" => archive_handler,
    "crate" => crate_handler,
    "git" => git_handler
)

end # modulegit@github.com:colinxs/NixSourcerer.jl.git
