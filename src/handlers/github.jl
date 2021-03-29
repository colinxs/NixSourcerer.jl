# TODO add ssh/https option
# TODO submodules when private
# TODO private tarball?

const GITHUB_SCHEMA = [
    SimpleSchema("owner", String, true),
    SimpleSchema("repo", String, true),
    ExclusiveSchema(("rev", "branch", "tag", "release"), (String, String, String, String), true),
    SimpleSchema("submodule", Bool, false)
]

function github_handler(name::AbstractString, spec::AbstractDict)
    verify(GITHUB_SCHEMA, name, spec)

    submodule = get(spec, "submodule", false)
    owner = spec["owner"]
    repo = spec["repo"]

    rev = if haskey(spec, "rev")
        spec["rev"]
    elseif haskey(spec, "branch")
        github_get_rev_sha_from_ref(owner, repo, "heads/$(spec["branch"])")
    elseif haskey(spec, "tag")
        github_get_rev_sha_from_ref(owner, repo, "tags/$(spec["tag"])")
    elseif haskey(spec, "release")
        tag = github_api_get(owner, repo, "releases/$(spec["release"])")["tag_name"]
        github_get_rev_sha_from_ref(owner, repo, "tags/$tag")
    end

    if submodule
        new_spec = subset(spec, "builtin", "rev", "submodule")
        new_spec["url"] = "https://github.com/$(owner)/$(repo).git"
        return git_handler(name, new_spec)
    else
        new_spec = subset(spec, "builtin")
        new_spec["url"] = "https://github.com/$(owner)/$(repo)/archive/$(rev).tar.gz"
        fetcher, fetcherargs, meta = archive_handler(name, new_spec)
        meta = merge(meta, Dict("rev" => rev)) 
        return fetcher, fetcherargs, meta 
    end
end

function github_get_rev_sha_from_ref(owner, repo, ref)
    github_api_get(owner, repo, "git/ref/$ref")["object"]["sha"]
end

function github_api_get(owner, repo, endpoint)
    r = HTTP.get(
        "https://api.github.com/repos/$(owner)/$(repo)/$endpoint", 
        Dict("Accept" => "application/vnd.github.v3+json")
    )
    return JSON.parse(String(r.body))
end
