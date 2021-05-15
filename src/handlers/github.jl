# TODO add ssh/https option
# TODO offset more work into git.jl
#  - e.g. get rid of github_get_rev_sha_from_ref

const GITHUB_SCHEMA = SchemaSet(
    SimpleSchema("owner", String, true),
    SimpleSchema("repo", String, true),
    ExclusiveSchema(
        ("rev", "branch", "tag", "release"), (String, String, String, String), true
    ),
    SimpleSchema("submodule", Bool, false),
)

function github_handler(name::AbstractString, spec::AbstractDict)
    submodule = get(spec, "submodule", false)
    owner = spec["owner"]
    repo = spec["repo"]

    if haskey(spec, "rev")
        rev = version = spec["rev"]
    elseif haskey(spec, "branch")
        rev = github_get_rev_sha_from_ref(owner, repo, "heads/$(spec["branch"])")
        version = spec["branch"]
    elseif haskey(spec, "tag")
        rev = github_get_rev_sha_from_ref(owner, repo, "tags/$(spec["tag"])")
        version = spec["tag"]
    elseif haskey(spec, "release")
        tag = github_api_get(owner, repo, "releases/$(spec["release"])")["tag_name"]
        rev = github_get_rev_sha_from_ref(owner, repo, "tags/$tag")
        version = tag
    else
        nixsourcerer_error("Unknown spec: ", string(spec))
    end

    if submodule
        new_spec = subset(spec, keys(DEFAULT_SCHEMA_SET)..., "submodule", "builtin")
        new_spec["rev"] = rev
        new_spec["url"] = "https://github.com/$(owner)/$(repo).git"
        new_spec["name"] = git_short_rev(rev) 
        source = git_handler(name, new_spec)
        source.version = version
        return source
    else
        new_spec = subset(spec, keys(DEFAULT_SCHEMA_SET)...)
        new_spec["url"] = "https://github.com/$(owner)/$(repo)/archive/$(rev).tar.gz"
        new_spec["name"] = git_short_rev(rev) 
        source = archive_handler(name, new_spec)
        return Source(;
            pname=name,
            version,
            fetcher_name=source.fetcher_name,
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
