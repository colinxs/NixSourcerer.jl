{ pkgs ? import <nixpkgs> { } }: {
  meta = { "pkgServer" = "https://pkg.julialang.org"; };
  depot = {
    "artifacts/43eef4d016f011145955de2ba33450dda0536252" =
      (pkgs.juliaPlatform.fetchPkgServer {
        "endPoint" = "/artifact/43eef4d016f011145955de2ba33450dda0536252";
        "name" = "Git";
        "server" = "https://pkg.julialang.org";
        "sha256" = "1lpdlvy4hgrxl1lmjk58yppc5vfpfr9zsjyqflxvq92dlqsavbrw";
      });
    "artifacts/473dc2ed3d46252c87733b7fdca3da64c6f9f917" =
      (pkgs.juliaPlatform.fetchPkgServer {
        "endPoint" = "/artifact/473dc2ed3d46252c87733b7fdca3da64c6f9f917";
        "name" = "Libiconv";
        "server" = "https://pkg.julialang.org";
        "sha256" = "1vnxgwnjgi3j0khppv5frq3vvw5wxvib5680xlvhcd5dar36hby2";
      });
    "artifacts/93d795500c7b63f53b10478c17435f32e7a3c443" =
      (pkgs.juliaPlatform.fetchPkgServer {
        "endPoint" = "/artifact/93d795500c7b63f53b10478c17435f32e7a3c443";
        "name" = "Gettext";
        "server" = "https://pkg.julialang.org";
        "sha256" = "0wbqihac7yhlwihf91bbmjkizwra122xvxz4zrsgdnyzpbq4zycl";
      });
    "artifacts/c91b35452c8fa91e8ac43993a2bc8fb4f78476bb" =
      (pkgs.juliaPlatform.fetchPkgServer {
        "endPoint" = "/artifact/c91b35452c8fa91e8ac43993a2bc8fb4f78476bb";
        "name" = "XML2";
        "server" = "https://pkg.julialang.org";
        "sha256" = "01blvcx6dmq7ywzwnbhbhpwqqydknwdz2av5b2fmipz6367ad4hl";
      });
    "artifacts/e6e5f41352118bbeb44677765ebccab8c151c72a" =
      (pkgs.juliaPlatform.fetchPkgServer {
        "endPoint" = "/artifact/e6e5f41352118bbeb44677765ebccab8c151c72a";
        "name" = "OpenSSL";
        "server" = "https://pkg.julialang.org";
        "sha256" = "025j774gnawmg50j9vizkw3vy857qjhscjd29iqc45lhx9ni76d7";
      });
    "artifacts/f371e7030764d7d3b86474ca985d35b87195302b" =
      (pkgs.juliaPlatform.fetchPkgServer {
        "endPoint" = "/artifact/f371e7030764d7d3b86474ca985d35b87195302b";
        "name" = "Expat";
        "server" = "https://pkg.julialang.org";
        "sha256" = "0g98ll698h6g6z5ldibh6ql8w7sq6qg90favjddc38dv7bwqil8d";
      });
    "packages/ArgParse/bylyV" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/c7e460c6-2fb9-53a9-8c5b-16f535851c63/3102bce13da501c9104df33549f511cd25264d7d";
      "name" = "ArgParse";
      "server" = "https://pkg.julialang.org";
      "sha256" = "02r4b0zj3cll0s7gpy2g6nya0s0rl7h337dqa9w2glmd3av3a4x8";
    });
    "packages/Expat_jll/InUJD" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/2e619515-83b5-522b-bb60-26c02a35a201/1402e52fcda25064f51c77a9655ce8680b76acf0";
      "name" = "Expat_jll";
      "server" = "https://pkg.julialang.org";
      "sha256" = "01g1wiyl6s9558s9im2ird0q18cvq98mvhn6ipjh9kb1v73khzd2";
    });
    "packages/Gettext_jll/ogctH" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/78b55507-aeef-58d4-861c-77aaff3498b1/8c14294a079216000a0bdca5ec5a447f073ddc9d";
      "name" = "Gettext_jll";
      "server" = "https://pkg.julialang.org";
      "sha256" = "1k6l48sr7dvfjp96lqabcqnxjjsx4cq7bdvn131gys0n2j954f2y";
    });
    "packages/GitCommand/p108F" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/49b5b516-ca3f-4003-a081-42bdcf55082d/d4633859cf3f8c75f385c70095f8f07d4a1739d1";
      "name" = "GitCommand";
      "server" = "https://pkg.julialang.org";
      "sha256" = "1vxkz5wwzdsvynyls3s2w8d5i98kv9f04cfdvl1yxsh5v8mfqyaf";
    });
    "packages/Git_jll/zXJkl" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/f8c6e375-362e-5223-8a59-34ff63f689eb/33be385f3432a5a5b7f6965af9592d4407f3167f";
      "name" = "Git_jll";
      "server" = "https://pkg.julialang.org";
      "sha256" = "1bbdkj791f9ciizav7hy40z3zm1c1a824z4l4di80hn3d9pyghw4";
    });
    "packages/HTTP/cxgat" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/cd3eb016-35fb-5094-929b-558a96fad6f3/c9f380c76d8aaa1fa7ea9cf97bddbc0d5b15adc2";
      "name" = "HTTP";
      "server" = "https://pkg.julialang.org";
      "sha256" = "1qb4dr85w2f9fqzilm7wmr9nbihmsli92fmwafwfsg79bqnb45qh";
    });
    "packages/IniFile/R4eEN" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/83e8ac13-25f8-5344-8a64-a9f2b223428f/098e4d2c533924c921f9f9847274f2ad89e018b8";
      "name" = "IniFile";
      "server" = "https://pkg.julialang.org";
      "sha256" = "19cn41w04hikrqdzlxhrgf21rfqhkvj9x1zvwh3yz9hqbf350xs9";
    });
    "packages/JLLWrappers/bkwIo" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/692b3bcd-3c85-4b1f-b108-f13ce0eb3210/642a199af8b68253517b80bd3bfd17eb4e84df6e";
      "name" = "JLLWrappers";
      "server" = "https://pkg.julialang.org";
      "sha256" = "0v7xhsv9z16d657yp47vgc86ggc01i1wigqh3n0d7i1s84z7xa0h";
    });
    "packages/JSON/3rsiS" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/682c06a0-de6a-54ab-a142-c8b1cf79cde6/81690084b6198a2e1da36fcfda16eeca9f9f24e4";
      "name" = "JSON";
      "server" = "https://pkg.julialang.org";
      "sha256" = "1f9k613kbknmp4fgjxvjaw4d5sfbx8a5hmcszmp1w9rqfqngjx9m";
    });
    "packages/Libiconv_jll/bLsPg" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/94ce4f54-9a6c-5748-9c1c-f9c7231a4531/8e924324b2e9275a51407a4e06deb3455b1e359f";
      "name" = "Libiconv_jll";
      "server" = "https://pkg.julialang.org";
      "sha256" = "07xd1lbp8ldavxpik9h40wx80mfaf0isz9jza4g7xgfcbyfqh1d8";
    });
    "packages/MbedTLS/4YY6E" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/739be429-bea8-5141-9913-cc70e7f3736d/1c38e51c3d08ef2278062ebceade0e46cefc96fe";
      "name" = "MbedTLS";
      "server" = "https://pkg.julialang.org";
      "sha256" = "0zjzf2r57l24n3k0gcqkvx3izwn5827iv9ak0lqix0aa5967wvfb";
    });
    "packages/OpenSSL_jll/l2Av2" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/458c3c95-2e84-50aa-8efc-19380b2a3a95/71bbbc616a1d710879f5a1021bcba65ffba6ce58";
      "name" = "OpenSSL_jll";
      "server" = "https://pkg.julialang.org";
      "sha256" = "15317wll2b1nks8ayg633ar8d9n3sil2nn4rrx165jdgsf2zndij";
    });
    "packages/Parsers/rIikS" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/69de0a69-1ddd-5017-9359-2bf0b02dc9f0/c8abc88faa3f7a3950832ac5d6e690881590d6dc";
      "name" = "Parsers";
      "server" = "https://pkg.julialang.org";
      "sha256" = "1gz3drd5334xrbx2ms33hiifkd0q1in4ywc92xvrkq3xgzdjqjdk";
    });
    "packages/Preferences/BbvxU" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/21216c6a-2e73-6563-6e65-726566657250/ea79e4c9077208cd3bc5d29631a26bc0cff78902";
      "name" = "Preferences";
      "server" = "https://pkg.julialang.org";
      "sha256" = "010bn42gqj81j2bi7zswfvh0g74g2pj28iqhncnpnhfg9znsp0li";
    });
    "packages/TextWrap/DsImh" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/b718987f-49a8-5099-9789-dcd902bef87d/9250ef9b01b66667380cf3275b3f7488d0e25faf";
      "name" = "TextWrap";
      "server" = "https://pkg.julialang.org";
      "sha256" = "1nlhi9f9y6nmnjq1z9d60ql39ajpbgc93ji0z7blnddyf48i6zdy";
    });
    "packages/URIs/hubHc" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4/7855809b88d7b16e9b029afd17880930626f54a2";
      "name" = "URIs";
      "server" = "https://pkg.julialang.org";
      "sha256" = "0fqyagsqks5za7m0czafr34m2xh5501f689k9cn5x3npajdnh2r3";
    });
    "packages/XML2_jll/Slt3Q" = (pkgs.juliaPlatform.fetchPkgServer {
      "endPoint" =
        "/package/02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a/afd2b541e8fd425cd3b7aa55932a257035ab4a70";
      "name" = "XML2_jll";
      "server" = "https://pkg.julialang.org";
      "sha256" = "18skv7nkihlxs0gk01llg6nq08fnwk98li9rl2vx1azc2r6x1jwf";
    });
    "registries/General" = (pkgs.juliaPlatform.fetchPkgServer {
      "name" = "General";
      "server" = "https://pkg.julialang.org";
      "sha256" = "1lrly3kyk3ns11pkqpm85grp7zbwzzm7alxaffw45b22dgawpza5";
      "url" =
        "https://pkg.julialang.org/registry/23338594-aafe-5451-b93e-139f81909106/40fd34e9d0e8864ec57e14290b5c1da262031061";
    });
    "registries/JuliaRegistry" = (builtins.fetchGit {
      "rev" = "0151ec459b6cd42b89f89d50ed361399fb027464";
      "url" = "https://github.com/colinxs/JuliaRegistry.git";
    });
  };
}
