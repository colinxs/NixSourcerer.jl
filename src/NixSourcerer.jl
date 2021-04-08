# TODO delete unneeded stuff
# TODO bootstrap nixpkgs

module NixSourcerer

using Base
using TOML
using JSON
using HTTP
using GitCommand
using Dates
using ArgParse


export update
export update_package


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
