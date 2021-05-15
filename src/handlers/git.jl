# TODO allow ref to be sourceified

const GIT_SCHEMA = SchemaSet(
    SimpleSchema("url", String, true),
    ExclusiveSchema(("rev", "branch", "tag"), (String, String, String), true),
    SimpleSchema("submodule", Bool, false),
)

function git_handler(name, spec)
    # NOTE pkgs.fetchgit appears to be faster because shallow clone
    builtin = get(spec, "builtin", false)
    submodule = get(spec, "submodule", false)
    url = spec["url"]

    if haskey(spec, "rev")
        # TODO is this correct when not sourceifying commit? 
        # It's what Nix builtins.fetchGit defaults to.
        # Should be refs/heads/HEAD but that errors.
        ref = "HEAD"
        rev = spec["rev"]
    elseif haskey(spec, "branch")
        ref = "refs/heads/$(spec["branch"])"
        rev = git_ref2rev(url, ref)
    elseif haskey(spec, "tag")
        ref = "refs/tags/$(spec["tag"])"
        rev = git_ref2rev(url, ref)
    else
        nixsourcerer_error("Unknown spec: ", string(spec))
    end

    fetcher_args = subset(spec, "url")
    fetcher_args["rev"] = rev
    fetcher_args["name"] = get(spec, "name", git_short_rev(rev))
    if builtin && submodule
        # TODO nix 2.4 fetchGit
        error("Cannot fetch submodules with builtins.fetchGit (until Nix 2.4)")
    elseif builtin && !submodule
        fetcher_name = "builtins.fetchGit"
        fetcher_args["ref"] = ref
        # TODO
        # Force build since nix-prefetch doesn't built builtins.fetchGit
        # build_source(fetcher_name, fetcher_args)
    else
        # TODO fetchgit doesn't have ref option
        fetcher_name = "pkgs.fetchgit"
        fetcher_args["fetchSubmodules"] = submodule
        fetcher_args["sha256"] = get_sha256(fetcher_name, fetcher_args)
    end

    return Source(; pname=name, version=rev, fetcher_name, fetcher_args)
end

# TODO kind of a hack
function git_ref2rev(url::AbstractString, ref::AbstractString)
    output = strip(read(`$(git()) ls-remote $url $ref`, String))
    lines = split(output, '\n')
    @assert length(lines) == 1
    columns = split(lines[1], '\t')
    @assert length(columns) == 2
    rev = columns[1]

    @assert match(r"\b([a-f0-9]{40})\b", rev) != nothing
    return rev
end
