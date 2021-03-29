# TODO allow ref to be specified

const GIT_SCHEMA = [
    SimpleSchema("url", String, true),
    ExclusiveSchema(("rev", "branch", "tag"), (String, String, String), true),
    SimpleSchema("submodule", Bool, false)
]

function git_handler(name, spec)
    verify(GIT_SCHEMA, name, spec)

    url = spec["url"] 
    builtin = get(spec, "builtin", false)
    submodule = get(spec, "submodule", false)
    if haskey(spec, "rev")
        # TODO is this correct when not specifying commit?
        ref = "refs/heads/HEAD"
        rev = spec["rev"]
    elseif haskey(spec, "branch")
        ref = "refs/heads/$(spec["branch"])"
        rev = git_ref2rev(url, ref)
    elseif haskey(spec, "tag")
        ref = "refs/tags/$(spec["tag"])"
        rev = git_ref2rev(url, ref)
    end

    fetcherargs = subset(spec, "url")
    fetcherargs["rev"] = rev
    if builtin && submodule
        # TODO nix 2.4 fetchGit
        error("Cannot fetch submodules with builtins.fetchGit (until Nix 2.4)")
    elseif builtin && !submodule
        fetcher = "builtins.fetchGit"
        fetcherargs["ref"] = ref
    else # !builtin || submodule
        # TODO fetchgit doesn't have ref option
        fetcher = "pkgs.fetchgit"
        fetcherargs["sha256"] = get_sha256(fetcher, fetcherargs)
    end

    meta = Dict()
    meta["ref"] = ref

    return fetcher, fetcherargs, Dict()
end

function git_ref2rev(url::AbstractString, ref::AbstractString)
    output = strip(rundebug(`$(git()) ls-remote $url $ref`, true))
    lines = split(strip(output), '\n')
    @assert length(lines) == 1
    columns = split(lines[1], '\t')
    @assert length(columns) == 2
    rev = columns[1]
    @assert match(r"\b([a-f0-9]{40})\b", rev) != nothing
    return rev
end

