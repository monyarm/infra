---
name: feedback-linkfiles-vs-linkfarm
description: "lib/files.nix's linkFiles returns a home-manager file-spec attrset, not a buildable directory"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5ac9d091-64cb-4c8b-bf5a-bdba0522e8d0
---

`linkFiles`/`linkContents` (`lib/files.nix`) return an attrset shaped for
home-manager's `xdg.dataFile`/`xdg.configFile` (`{ "path" = { source;
recursive; }; }`) — not a real derivation. Using it inside a plain Nix
builder function that needs an actual directory back (to feed into
`pkgs.runCommand`/`mkModDir`-style layering) silently produces the wrong
shape; the error only surfaces later as a confusing eval failure at the
consumption site, not where the mistake was made.

**Why:** discovered while building `mkPrismInstance` (Minecraft module) —
tried to compose mod directories with `linkFiles`, which is the wrong tool
outside a home-manager module context.

**How to apply:** inside a pure builder function (not directly assigned to
an `xdg.*File` option), use `pkgs.linkFarm` to place a list of packages at
their own name inside one real directory derivation. Reserve `linkFiles`
for actually building an `xdg.dataFile`/`xdg.configFile` value.

Related: a module-local builder split into its own file (e.g.
`mkPrismInstance.nix`, mirroring ScummVM's inline `mkScummVMGame`) is not
automatically available via `_module.args` the way `customLib` functions
are — it must be explicitly `import`ed and destructured in the consuming
module. `hosts/modules/lib.nix` only spreads `lib/*.nix`'s exports; nothing
auto-discovers sibling files in a `hosts/home/*/games/*/` directory.
