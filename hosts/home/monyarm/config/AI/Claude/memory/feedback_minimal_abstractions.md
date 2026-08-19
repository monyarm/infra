______________________________________________________________________

## name: feedback-minimal-abstractions description: Prefers reusing existing minimal patterns over introducing new generic wrappers; push back on unnecessary abstraction during planning. metadata: node_type: memory type: feedback originSessionId: 0e784c34-885f-4e4e-b82a-0a308b62f728

Don't introduce a new generic/wrapper function when an existing minimal pattern already does the job. During a large lib/ fetcher-unification refactor, I proposed a `fetchCurl` generic to wrap `pkgs.fetchurl` calls; the user rejected it: "there's actually no need for it, as it can just remain `pkgs.fetchurl` with `curlOptsList`, like how some existing ones are." Several existing fetchers (`fetchWithReferrer`, `fetchChaosium`, `fetchSteamStoreAsset`) were already thin `pkgs.fetchurl` wrappers — that itself was already the minimal idiomatic shape, and wrapping it in yet another layer was needless.

Similarly, when I designed a new `fetchSteamCdnImages` function, the user specified it should reuse the **existing** `splitFiles` helper (already used by `fetchSteamCards` for the same "single FOD, split into named files" shape) rather than inventing new path-concatenation logic.

**Why:** the user actively favors DRY-through-reuse over DRY-through-new-abstraction. A new helper is only worth it when it removes real duplication across 3+ call sites — for a single call site or a shape that already has a minimal established pattern, just use that pattern directly.

**How to apply:** when planning a refactor, before adding a new generic/wrapper function, check whether an existing helper (in this repo: `lib/files.nix`, `lib/strings.nix`, `lib/misc.nix`'s `dispatchExt`) already covers the shape, and prefer wiring into that over inventing something new. Present the "no new abstraction needed" option explicitly during planning rather than defaulting to building one.
