---
name: feedback-use-prefetch-scripts-pattern
description: "For prefetching any fetcher's fixed-output hash (fetchSteam, fetchSteamCdnImages, etc.), check scripts/prefetch/*.sh first and follow that pattern instead of inventing a full homeConfigurations/nixosConfigurations eval path."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c0a75eb0-4eed-460b-9187-ee60ed4bb92c
---

`scripts/prefetch/` already holds hash-discovery scripts (`prefetchSteamCdnImages.sh`,
`prefetchSteamCards.sh`, `prefetch_gog.sh`, etc.) that do a minimal, targeted
`nix-build -E` against the fetcher directly (`lib/fetchers.nix`'s function with a
placeholder `sha256`, read the `got:` hash from the failure, rebuild to verify). None
of them go through `homeConfigurations`/`nixosConfigurations` — that's unnecessary
overhead and pulls in the whole home-manager module graph just to force one FOD.

**Why:** User flagged that for DOTT's `fetchSteam` hash I built a `nix build --expr
'(builtins.getFlake ...).homeConfigurations.monyarm.config.games.scummvm.games.dott.path'`
command instead of a `prefetchSteam`-style targeted script — even though no such script
existed yet for `fetchSteam` specifically (only `fetchSteamCdnImages`/`fetchSteamCards`
have one). The existing scripts are the intended template.

**How to apply:** Before prefetching any fixed-output hash, `ls scripts/prefetch/` for
an existing script covering that fetcher. If one exists, use it as-is or adapt its
`build_expr`-with-placeholder-then-rebuild structure for a new fetcher — don't reach for
a full flake-output eval path (`homeConfigurations.*`/`nixosConfigurations.*`) as the
default. If no script exists for the fetcher in question, consider whether one *should*
be added following the same pattern, especially if it'll be needed again.
