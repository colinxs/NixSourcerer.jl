using NixSourcerer
using TOML
using Downloads: download
using Test


function nix_file_sha256(path)
    strip(read(`nix-hash --type sha256 --base32 --flat $path`, String))
end

function nix_dir_hash(path)
    strip(read(`nix-hash --type sha256 --base32 $path`, String))
end


function nix_eval_source_attr(dir, attr)
    expr = "( (import $(dir)/Sources.nix {}).$(attr) )"
    strip(read(`nix eval --raw $(expr)`, String))
end

function compare_source_attr(dir, truth, attr::AbstractString)
    nix_eval_source_attr(dir, attr) == truth[attr]
end

function compare_source_attrs(dir, truth)
    @testset "attr: $(attr)" for attr in keys(truth)
        @test compare_source_attr(dir, truth, attr)
    end
end


function with_update(fn::Function, toml::AbstractDict)
    mktempdir() do dir
        open("$(dir)/Sources.toml", "w") do io
            TOML.print(io, toml)
        end
        update(dir)
        fn(dir)
    end
end


function runtest(toml::AbstractDict, truth::AbstractDict)
    with_update(toml) do dir
        compare_source_attrs(dir, truth)
    end
end


# TODO
# function nested_dict(entries::Pair...)
#     x = Dict()
#     for (ks, v) in entries
#         x_cur = x
#         while length(ks) > 1
#             @info ks
#             k, ks = Base.first(ks), Base.tail(ks)
#             x_cur = x_cur[k] = Dict()
#         end
#         x_cur[only(ks)] = v
#     end
#     x
# end

