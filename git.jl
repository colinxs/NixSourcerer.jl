using LibGit2

function is_git_repo(path::String)
    try
        GitRepo(path)
        return true
    catch
        return false
    end
end


# refspec = "+refs/heads/mybranch:refs/remotes/origin/mybranch"
function get_repo_meta(path::String)
    repo = GitRepo(path)

    branch_ref = LibGit2.head(repo);
    ref = LibGit2.name(branch_ref)
    shortref = LibGit2.shortname(branch_ref)
    rev = string(LibGit2.head_oid(repo))

    remote_names = LibGit2.remotes(repo)
    remote_urls = map(remote_names) do name
        LibGit2.url(LibGit2.get(LibGit2.GitRemote, repo, name))
    end

    return (;ref, shortref, rev, remote_names, remote_urls)
end
x=get_repo_meta("/home/colinxs/.julia/registries/JuliaRegistry")
