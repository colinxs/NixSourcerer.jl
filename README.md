# TODO

- it's weird that manifest is .meta but project is dict
```
m.sources["rnix-lsp"].meta["cargoSha256"] = sha
p.specs["rnix-lsp"]["meta"]["cargoSha256"] = sha
```
- derivation name? parallel download?
- change update script from update.jl to nix-update.jl
- run_supress: replace out=true with out=String for type to parse output
