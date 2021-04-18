{ pkgs ? import <nixpkgs> { } }: { "36b54c61-190e-5a5f-82d5-6f0a962d7362" = let
  fetcher = builtins.fetchurl;
  pname = "PushVectors-0.2.1";
  fetcherName = "builtins.fetchurl";
  version = "04v87ayrv1frmga191bxlsksnayimc8p87ar3qayxr6y6d5pywnx";
  name = "PushVectors-0.2.1-04v87ayrv1frmga191bxlsksnayimc8p87ar3qayxr6y6d5pywnx";
  outPath = fetcher fetcherArgs;
  meta = { "name" = "PushVectors"; "tree_hash" = "c7466c767062fa922a1689390a8aadb138253ecf"; "version" = "0.2.1"; };
  fetcherArgs = { "sha256" = "04v87ayrv1frmga191bxlsksnayimc8p87ar3qayxr6y6d5pywnx"; "url" = "https://pkg.julialang.org/package/36b54c61-190e-5a5f-82d5-6f0a962d7362/c7466c767062fa922a1689390a8aadb138253ecf"; };
in
{ inherit fetcher pname fetcherName version name outPath meta fetcherArgs; }; "5c5e3362-9445-4819-9f95-51c44c51adeb" = let
  fetcher = pkgs.fetchgit;
  pname = "UniversalLogger-0.2.0";
  fetcherName = "pkgs.fetchgit";
  version = "d9433c480dd7e64c7f042cf2bfdd63e8f1d99be9";
  name = "UniversalLogger-0.2.0-d9433c480dd7e64c7f042cf2bfdd63e8f1d99be9";
  outPath = fetcher fetcherArgs;
  meta = { "name" = "UniversalLogger"; "tree_hash" = "d9433c480dd7e64c7f042cf2bfdd63e8f1d99be9"; "version" = "0.2.0"; };
  fetcherArgs = { "sha256" = "15l4ldl40z82dwkqsnixchbhmnczdsy9b7glgj6qc16pmw8z75x5"; "rev" = "d9433c480dd7e64c7f042cf2bfdd63e8f1d99be9"; "url" = "https://github.com/Lyceum/UniversalLogger.jl.git"; };
in
{ inherit fetcher pname fetcherName version name outPath meta fetcherArgs; }; "90137ffa-7385-5640-81b9-e52037218182" = let
  fetcher = pkgs.fetchgit;
  pname = "StaticArrays-1.1.0";
  fetcherName = "pkgs.fetchgit";
  version = "1c61c3c73460e15d293f6e26fe9068ecb3cb58b6";
  name = "StaticArrays-1.1.0-1c61c3c73460e15d293f6e26fe9068ecb3cb58b6";
  outPath = fetcher fetcherArgs;
  meta = { "name" = "StaticArrays"; "tree_hash" = "1c61c3c73460e15d293f6e26fe9068ecb3cb58b6"; "version" = "1.1.0"; };
  fetcherArgs = { "sha256" = "1nsg61ysihdrxl3xg70v652pxkljqaka2dfr0rvrgckdw5axf55b"; "rev" = "1c61c3c73460e15d293f6e26fe9068ecb3cb58b6"; "url" = "https://github.com/JuliaArrays/StaticArrays.jl.git"; };
in
{ inherit fetcher pname fetcherName version name outPath meta fetcherArgs; }; }
