---
name: feedback-attrsof-entries-cant-reference-siblings
description: "A types.attrsOf-typed option's own entry cannot reference config.<same-option-path>.<anyOtherKey> at all -- causes real infinite recursion, not fixable by rec/with/plain-dotted-access syntax choice"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 16dd47ec-4739-46a7-bab4-6ccc43f50f6a
---

Tried to add `games.doom.wads.wadfusion = mkWadFusion { inherit (config.games.doom.wads) doom doom2 ...; };` in `hosts/home/monyarm/games/Doom/wad/wadfusion.nix` -- infinite recursion, every time, regardless of whether the reference was written as `with config.games.doom.wads; {...}`, `rec { ...; wadfusion = ...; }` with cross-file lookups still going through `config.games.doom.wads.X`, or plain `inherit (config.games.doom.wads) doom;`.

Root cause (confirmed via `--show-trace`, not guessed): `games.doom.wads` is `lib.types.attrsOf lib.types.package` (`Doom/wad/default.nix:56`). `types.attrsOf`'s own `merge` in nixpkgs (`lib/types.nix` around line 1022, comment literally says "Meaning it is less lazy") does `filterAttrs (n: v: v.optionalValue ? value) (zipAttrsWith ...)` over the *whole* merged set just to know which keys are actually defined -- that forces every sibling key's merged value as a side effect of computing any single one. So a `wadfusion` entry that reads `config.games.doom.wads.doom` needs `games.doom.wads`'s full mergedValue, which needs `wadfusion`'s own value forced (to run that same filterAttrs check) -- genuine self-reference, not an artifact of `with`'s eagerness (I initially assumed only `with` forced things and plain `.` selection wouldn't -- wrong, both hit it).

**Why:** [[project_packages_two_overlay_sites]] is about the same "watch for repo-wide registries with implicit cross-file coupling" theme, but this is a distinct, sharper trap: it's not about remembering to update multiple files, it's that the data structure itself (`attrsOf`) structurally forbids this cross-key dependency no matter how it's phrased.

**How to apply:** never make a `types.attrsOf`-typed registry entry (this repo's `games.doom.wads`, and likely similar per-game wad/source registries elsewhere) depend on `config.<same-registry-path>.<anotherKey>`. If a derivation genuinely needs several sibling registry entries as inputs (like WadFusion needing `doom`/`doom2`/etc.), compute it as a plain `let`-bound value *outside* the registry's own attrset (reading `config.games.doom.wads.X` is fine from there), and only feed the *result* into a different option (`programs.steam.games`, in this case) -- never register the computed value back into the same `attrsOf` option itself. `types.lazyAttrsOf` would sidestep this if the registry's own type ever needs changing, but that's a bigger, unrelated change.
