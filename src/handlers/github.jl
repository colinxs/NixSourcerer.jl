# TODO add ssh/https option

const GITHUB_SCHEMA = SchemaSet(
    SimpleSchema("owner", String, true),
    SimpleSchema("repo", String, true),
    ExclusiveSchema(
        ("rev", "branch", "tag", "release"), (String, String, String, String), true
    ),
    SimpleSchema("submodule", Bool, false),
)

function github_handler(name::AbstractString, source::AbstractDict)
    submodule = get(source, "submodule", false)
    owner = source["owner"]
    repo = source["repo"]

    rev = if haskey(source, "rev")
        source["rev"]
    elseif haskey(source, "branch")
        github_get_rev_sha_from_ref(owner, repo, "heads/$(source["branch"])")
    elseif haskey(source, "tag")
        github_get_rev_sha_from_ref(owner, repo, "tags/$(source["tag"])")
    elseif haskey(source, "release")
        tag = github_api_get(owner, repo, "releases/$(source["release"])")["tag_name"]
        github_get_rev_sha_from_ref(owner, repo, "tags/$tag")
    end

    if submodule
        new_source = subset(
            source, keys(DEFAULT_SCHEMA_SET)..., "rev", "submodule", "builtin"
        )
        new_source["url"] = "https://github.com/$(owner)/$(repo).git"
        return git_handler(name, new_source)
    else
        new_source = subset(source, keys(DEFAULT_SCHEMA_SET)...)
        new_source["url"] = "https://github.com/$(owner)/$(repo)/archive/$(rev).tar.gz"
        source = archive_handler(name, new_source)
        return Source(;
            pname=name,
            version=rev,
            fetcher=source.fetcher,
            fetcher_args=source.fetcher_args,
        )
    end
end

function github_get_rev_sha_from_ref(owner, repo, ref)
    return github_api_get(owner, repo, "git/ref/$ref")["object"]["sha"]
end

function github_api_get(owner, repo, endpoint)
    headers = Dict()
    headers["Accept"] = "application/vnd.github.v3+json"
    if haskey(ENV, "GITHUB_TOKEN")
        headers["Authorization"] = "token $(ENV["GITHUB_TOKEN"])"
    end
    r = HTTP.get("https://api.github.com/repos/$(owner)/$(repo)/$endpoint", headers)
    return JSON.parse(String(r.body))
end
