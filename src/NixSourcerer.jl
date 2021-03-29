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


include("schema.jl")
include("util.jl")
include("nix.jl")

include("handlers/git.jl")
include("handlers/github.jl")
include("handlers/file.jl")
include("handlers/archive.jl")
include("handlers/crate.jl")

const HANDLERS = Dict(
    "github" => github_handler,
    "file" => file_handler,
    "archive" => archive_handler,
    "crate" => crate_handler,
    "git" => git_handler
)

function process_dir(dir)
    tomlpath = joinpath(dir, "sources.toml")
    nixpath = joinpath(dir, "sources.nix")

    if !isfile(tomlpath)
        error("$tomlpath does not exist!")
    end

    toml = TOML.parsefile(tomlpath)

    entry_specs = Dict()
    @sync for (name, spec) in toml
        if !haskey(spec, "type")
            error("Must specify the \"type\" of source $name")
        elseif !haskey(HANDLERS, spec["type"])
            error("Unknown type \"$(spec["type"])\" for source $name")
        else
            @async begin
                fetcher, fetcherargs, meta = HANDLERS[spec["type"]](name, spec)

                meta["lastChecked"] = round(Integer, time()) 
                meta["original"] = spec

                entry_specs[name] = (fetcher, fetcherargs, meta)
            end
        end
    end

    nixexpr = generate_nixexpr(entry_specs)
    open(nixpath, "w") do io
        write(io, nixexpr)
    end
end



end # module
