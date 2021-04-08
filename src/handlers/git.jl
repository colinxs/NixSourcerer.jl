# TODO allow ref to be sourceified

const GIT_SCHEMA = SchemaSet(
    SimpleSchema("url", String, true),
    ExclusiveSchema(("rev", "branch", "tag"), (String, String, String), true),
    SimpleSchema("submodule", Bool, false),
)

function git_handler(name, source)
    # NOTE pkgs.fetchgit appears to be faster because shallow clone
    builtin = get(source, "builtin", false)
    submodule = get(source, "submodule", false)
    url = source["url"]

    if haskey(source, "rev")
        # TODO is this correct when not sourceifying commit? 
        # It's what Nix builtins.fetchGit defaults to.
        # Should be refs/heads/HEAD but that errors.
        ref = "HEAD"
        rev = source["rev"]
    elseif haskey(source, "branch")
        ref = "refs/heads/$(source["branch"])"
        rev = git_ref2rev(url, ref)
    elseif haskey(source, "tag")
        ref = "refs/tags/$(source["tag"])"
        rev = git_ref2rev(url, ref)
    end

    fetcher_args = subset(source, "url")
    fetcher_args["rev"] = rev
    if builtin && submodule
        # TODO nix 2.4 fetchGit
        error("Cannot fetch submodules with builtins.fetchGit (until Nix 2.4)")
    elseif builtin && !submodule
        fetcher = "builtins.fetchGit"
        fetcher_args["ref"] = ref
        # TODO
        # Force build since nix-prefetch doesn't built builtins.fetchGit
        build_source(fetcher, fetcher_args)
    else
        # TODO fetchgit doesn't have ref option
        fetcher = "pkgs.fetchgit"
        fetcher_args["sha256"] = get_sha256(fetcher, fetcher_args)
    end

    return Source(; pname=name, version=rev, fetcher, fetcher_args)
end

# TODO kind of a hack
function git_ref2rev(url::AbstractString, ref::AbstractString)
    output = strip(rundebug(`$(git()) ls-remote $url $ref`; stdout=true))
    lines = split(output, '\n')
    @assert length(lines) == 1
    columns = split(lines[1], '\t')
    @assert length(columns) == 2
    rev = columns[1]

    @assert match(r"\b([a-f0-9]{40})\b", rev) != nothing
    return rev
end
