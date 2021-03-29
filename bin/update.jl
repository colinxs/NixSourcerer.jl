#!/usr/bin/env bash
#=
JULIA="${JULIA:-julia --color=yes --startup-file=no}"
export JULIA_PROJECT="$(dirname $(dirname ${BASH_SOURCE[0]}))"

set -ex
${JULIA} -e 'using Pkg; Pkg.instantiate()'

export JULIA_LOAD_PATH="@"
exec ${JULIA} "${BASH_SOURCE[0]}" "$@"
=#

# TODO make shebang into template
# TODO suppress stderror from nix-prefetch
# TODO include name in fetcher request?
# TODO passthru extra arguments to fetcher?
# TODO change TOML sort so type first
# SRI hash (https://github.com/Mic92/nix-update/blob/e21c7830824e097611d046d5d5c7bdcce124a50f/nix_update/update.py#L33)
# cargohash?

module M

using TOML
using JSON
using HTTP


const NIX_PREFETCH_CMD = `nix-prefetch --output nix`


###
### GitHub 
###

github_api_base_url(owner, repo) = "https://api.github.com/repos/$(owner)/$(repo)/"

function github_latest_release_tag(owner, repo)
    r = HTTP.request("GET", github_api_base_url(owner, repo) * "releases/latest")
    return JSON.parse(String(r.body))["tag_name"]
end

function github_get_commit_sha_from_ref(owner, repo, ref)
    r = HTTP.request("GET", github_api_base_url(owner, repo) * "git/ref/$ref")
    return JSON.parse(String(r.body))["object"]["sha"]
end

function github_handler(key::AbstractString, spec::AbstractDict)
    if count(!isnothing, map(k -> get(spec, k, nothing), ("commit", "branch", "tag", "release"))) != 1
        error("Must specify exactly one of commit, branch, tag, or release")
    end


    rev = if haskey(spec, "commit") 
        spec["commit"]
    elseif haskey(spec, "branch") 
        github_get_commit_sha_from_ref(spec["owner"], spec["repo"], "heads/$(spec["branch"])")
    elseif haskey(spec, "tag") 
        github_get_commit_sha_from_ref(spec["owner"], spec["repo"], "tags/$(spec["tag"])")
    elseif haskey(spec, "release")
        tag = github_latest_release_tag(spec["owner"], spec["repo"])
        github_get_commit_sha_from_ref(spec["owner"], spec["repo"], "tags/$tag")
    end

    args = ["--name", key, "--owner", spec["owner"], "--repo", spec["repo"], "--rev", rev]

    if get(spec, "fetchSubmodules", false)
        push!(args, "--fetchSubmodules")
    end

    fetcher = "fetchFromGitHub"
    fetcherargs = read(`$NIX_PREFETCH_CMD $fetcher $args`, String)

    return fetcher, fetcherargs 
end


###
### File 
###

function file_handler(key::AbstractString, spec::AbstractDict)
    fetcher = "fetchurl"
    args = read(`$NIX_PREFETCH_CMD $fetcher --name $key --url $(spec["url"])`, String)

    return fetcher, args
end


###
### Archive
###

function archive_handler(key::AbstractString, spec::AbstractDict)
    fetcher = "fetchzip"
    args = read(`$NIX_PREFETCH_CMD $fetcher --name $key --url $(spec["url"])`, String)

    return fetcher, args
end


###
### Crate
###

function crate_handler(key::AbstractString, spec::AbstractDict)
    fetcher = "fetchCrate"
    args = read(`$NIX_PREFETCH_CMD $fetcher --name $key --pname $(spec["pname"]) --version $(spec["version"])`, String)

    return fetcher, args
end


const HANDLERS = Dict(
    "github" => github_handler,
    "file" => file_handler,
    "archive" => archive_handler,
    "crate" => crate_handler
)


###
### Formatting
###

function nixpkgs_fmt(nixexpr::String)
    stdin = IOBuffer(nixexpr)
    stdout = IOBuffer()
    run(pipeline(`nixpkgs-fmt`, stdin=stdin, stdout=stdout))
    return String(take!(stdout))
end

function format_fetcher_call(key, fetcher, args)
    try
    "$(strip(key)) = $(strip(fetcher)) $(strip(args));"
    catch   
        print(key)
        print(fetcher)
        print(args)
    end
end

function generate_nixexpr(nix_sources)
    fetcher_calls = []
    fetchers = Set()
    for key in sort(collect(keys(nix_sources)))
        fetcher, args = nix_sources[key]
        push!(fetcher_calls, format_fetcher_call(key, fetcher, args))
        push!(fetchers, fetcher)
    end

    signature = "{ $(join(fetchers, ", ")) }:"
    attrset = "{ $(join(fetcher_calls, "\n")) }"
    nixexpr = "$signature $attrset"

    return nixpkgs_fmt(nixexpr)
end


###
### Main
###

function process_dir(dir)
    tomlpath = joinpath(dir, "sources.toml")
    nixpath = joinpath(dir, "sources.nix")

    if !isfile(tomlpath)
        error("$tomlpath does not exist!")
    end

    toml = TOML.parsefile(tomlpath)

    nix_sources = Dict()
    @sync for (key, spec) in toml
        @async nix_sources[key] = HANDLERS[spec["type"]](key, spec)
    end

    nixexpr = generate_nixexpr(nix_sources)

    open(nixpath, "w") do io
        write(io, nixexpr)
    end
    open(tomlpath, "w") do io
        TOML.print(io, toml, sorted=true)
    end
end


function main()
    # path = ARGS[1]
    path = "$(@__DIR__)"
    process_dir(path)
end

end # module

M.main()
