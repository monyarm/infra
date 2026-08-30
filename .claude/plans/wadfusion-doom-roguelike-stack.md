# WadFusion + Doom infinite roguelike stack

## Plan revision

This document is both the research record and the implementation plan. The
implementation work should follow the dependency order below rather than the
order in which the research was collected.

Decisions confirmed after repository and upstream review:

- Classic `base/` Doom files intentionally replace the currently registered
  KEX `rerelease/` files. The current files were assumed to be classic and
  that assumption was wrong; the replacement is deliberate, not a temporary
  WadFusion workaround.
- WadFusion receives a named input attrset. Supported inputs that are not
  available are represented by `null`, rather than relying on positional list
  order. Required inputs fail clearly when null; optional inputs are omitted.
- The map merger uses DoomTools' script-driven `wadmerge`, specifically
  `MERGEMAPFILE`, not a nonexistent Python `wadmerge` library or the
  symbol-oriented `MERGEMAP` command.
- MOShuffle changes `nextmap`/`secretmap` at runtime. The map pool therefore
  does not need to be a connected campaign: ordinary standalone `MAPnn` maps
  can be shuffled. Maps with explicit scripted warps are an exception.
- The requested randomizer projects are Vandomizer (weapons/items and other
  spawn randomization) and Universal Entropy (monster-property
  randomization). They replace the placeholder names used in the earlier
  draft.
- Doom64, HXDD, Works of the Masters, and other exploratory ideas remain
  deferred until the Doom stack works end to end.

## wadsmoosh derivation

A Python tool (upstream original now retired, its own author's own words --
see "Fork landscape" below; `vburnin8tor/wadsmoosh-plus` is the one to build
against, per that same section) that merges
the classic id Software Doom releases -- `doom.wad`, `doom2.wad`, Final
Doom's `tnt.wad`/`plutonia.wad`, the Master Levels, `nerve.wad` (No Rest for
the Living), Sigil/Sigil II, and the two Xbox-exclusive secret levels
(`sewers.wad`/`betray.wad`) -- into one continuous `doom_complete.pk3`,
which some total-conversion megawad mods expect as their IWAD. Already
anticipated but unused in this repo: `Doom/conf.nix`'s `autoloadCategories`
list has `doom.id.wadsmoosh` and `doom.id.doom2.wadsmoosh` entries sitting
dead with nothing producing that content yet -- though on closer look those
are `*.Autoload` categories (files auto-loaded *alongside* an IWAD), the
wrong shape for `doom_complete.pk3` itself, which is consumed as an `-iwad`
(see "wires into" below).

### Fork landscape -- who to actually build against

Checked every fork/mirror reachable from the original via GitHub's API
(not just the two forks turned up by a first search pass), diffed their
`wadsmoosh_data.py`/ZScript content directly rather than trusting push
dates alone, and dropped the ones that turned out to be pure duplicates:

- **The original author retired the project outright.** JP LeBreton's
  own `GOODBYE.md` (dated 2024-08-10, two days after the KEX relaunch)
  explains why: the new port covers "100% of what WadSmoosh supported,"
  the new content (Legacy of Rust, new soundtrack) would take "100X more
  time" to support, and general maintainer burnout. No successor is
  named -- "anyone can fork the code and carry it onward." The canonical
  repo is now mirrored at `saegiru/wadsmoosh` (a fresh 2026 GitHub
  re-hosting of the same final Mercurial state, not new work); two more
  GitHub repos (`elf-alchemist/wadsmoosh-archive`,
  `UndeadZeratul/wadsmoosh-archive`) are byte-identical Mercurial-history
  preservation mirrors of the same original, not independently useful.
- **`atsb/WadSmoosh`** ("WadSmoosh - continued") turns out to be *less*
  expansive than wadsmoosh-plus, not more -- checked its actual
  `wadsmoosh_data.py`, not just README prose: its `WADS` list is just
  `doom`/`doom2`/`tnt`/`plutonia`/`nerve`/`sigil`/`sigil_shreds`/`sigil2`
  plus Unity-port variants (`doomu`/`doom2u`/etc, note the different
  naming than wadsmoosh-plus's `doomunity`/`doom2unity`) -- no Legacy of
  Rust, no community megawads, no Freedoom. It has zero forks of its own;
  nobody has built further on it. An earlier draft of this doc wrongly
  attributed Legacy-of-Rust support to atsb -- that was actually from
  misreading a wadsmoosh-plus source during an earlier research pass.
- **`nathan-hyan/wadsmoosh-freedoom`** is the actual root of the
  expansive lineage -- added Freedoom support on top of JP's original.
  Superseded by everything downstream; last touched Jan/Mar 2024.
- **`vanessakindell/wadsmoosh-plus`** (forked from nathan-hyan) added the
  full community-megawad roster (`tntr`/`pl2`/`prcp`/`neis`/`doomzero`/
  `hell2pay`/`perdgate`/`jptr_v40`/`tnt2_beta6`) and full Legacy of Rust/
  id24 support (`id1`/`id1-res`/`id24res`). This is the fork this doc has
  been researching against so far. Last own commit Dec 2024.
- Three further forks branch from vanessakindell, each with one real,
  narrow difference -- not just noise:
  - **`lgallindo/wadsmoosh-plus`** froze in Sept 2024, missing everything
    vanessakindell added afterward (`doomzero`, `prcp`, `jptr_v40`,
    `tnt2_beta6`, `id1-res`, `id24res`) -- *except* one spot where it's
    actually more complete: its `perdgate` lump-extraction list pulls
    `patches_perdgate`/`flats_perdgate` in addition to `graphics`/`music`;
    vanessakindell's (and everything downstream of it) only pulls
    `graphics`/`music`. Worth cherry-picking that one entry specifically
    when Perdition's Gate support gets wired in, since nothing downstream
    of vanessakindell picked it back up.
  - **`staticnation/wadsmoosh-plus`** makes one deliberate trade-off:
    drops `zscript/wf_music.zs` from the bundled output entirely
    (confirmed via diff), matching its commit message "stripped
    wf_music.zs dependency." That file is a runtime GZDoom
    `StaticEventHandler` (class name `WadFusionMusicHandler`) bundled
    into `doom_complete.pk3` -- it hooks map load/unload to let the
    player live-toggle two optional soundtracks that can't be expressed
    in static MAPINFO: Sigil/Sigil II's alternate Buckethead MP3 remix
    (`wf_sigil_shreds`/`wf_sigil2_shreds` cvars), and a full-game swap to
    Andrew Hulshult's remastered soundtrack (`wf_hulshult_idkfa`, backed
    by a large hardcoded old-lump-name to new-lump-name table). The class
    name traces to **WadFusion**, a separate sibling fork by the same
    author (the file's own copyright credits "Owlet VII, Vanessa
    Kindell" -- confirmed the same person via
    `vanessakindell/wadsmoosh-plus#18`, a third-party issue asking
    whether wadsmoosh-plus already covers what WadFusion covers:
    Legacy of Rust, id Deathmatch maps, and "Rejects of Master Levels"
    cut content). That issue is just a question, not evidence of an
    active conflict -- it's closed, and wadsmoosh-plus's own later
    commits suggest the Legacy-of-Rust overlap got absorbed
    independently rather than by merging WadFusion's code in. Staticnation
    never documented *why* they dropped the file beyond the commit
    message itself, so treat the WadFusion-compatibility motive as a
    plausible read of the class name, not a confirmed reason. Bottom
    line: skip this fork's change unless the Hulshult-soundtrack-toggle
    feature specifically is unwanted, since dropping it is a feature
    removal, not a bugfix.
  - **`vburnin8tor/wadsmoosh-plus`** -- **this is the one to build
    against.** Identical `wadsmoosh_data.py` to vanessakindell's (verified
    by diff, zero differences), but with 7 additional commits dated
    2026-03-31 -- confirmed via a separate GitHub user ID lookup to be a
    genuinely different maintainer, not a renamed vanessakindell account
    -- fixing real bugs in the bundled ZScript: `wf_xbox.zs` and
    `wf_music.zs` both previously called `.GetBool()` directly on
    `CVar.FindCVar(...)`'s result with no null check, which would crash
    if that cvar isn't registered; vburnin8tor's commits add the missing
    existence check before use (`"Check for existence of Xbox Secrets"`,
    `"remove weapSwap Type check"`). Most current, most expansive, and
    the only fork with recent bug-fixing activity at all.

Net recommendation: build against **`vburnin8tor/wadsmoosh-plus`**, and
separately pull `lgallindo`'s two extra `perdgate` lump categories into
the `WAD_LUMP_LISTS['perdgate']` entry when wiring up Perdition's Gate,
since that's a real improvement no one downstream carried forward. Skip
staticnation's `wf_music.zs` removal unless WadFusion (or a similar
conflicting mod) actually ends up in the stack.

### WadFusion is a second, real, actively-maintained tool -- not a fork to skip

`Owlet7/wadfusion` (pushed hours before this research pass) turns out to
be the *original author's own* continuation, not a community fork of
wadsmoosh-plus. Its own changelog: *"Now that WadSmoosh has ended its
development, forked and rebranded the project under a new name --
WadFusion"* (v1.0.0, 2024-09-22). Same person ("Owlet VII," credited
alongside Vanessa Kindell in wadsmoosh-plus's copyright header) went in
the *opposite* direction from wadsmoosh-plus at the same time: instead of
adding community megawads, WadFusion deliberately kept JP LeBreton's
"official content only" stance (its README repeats his exact wording
verbatim) and instead went deep on engine integration -- a rewritten
options menu, an alternate fullscreen HUD, "Full Run" mode (auto-continue
through every episode in default/release/chronological order),
multi-language localization, and real upstream collaboration (some of its
Legacy-of-Rust ZScript actors have since been merged into GZDoom/UZDoom
proper, per its own changelog). It's under active development today, not
a frozen fork.

Practical differences that matter for this repo:

- **Output is different and mutually exclusive**: `doom_fusion.ipk3`
  (gametype `doom.id.fusion`), not `doom_complete.pk3` -- the two tools'
  outputs aren't meant to merge, they're alternate "which complete IWAD"
  choices, same as this repo already exposes multiple IWAD variants as
  separate Steam shortcuts via `mkDoom`.
- **Requires UZDoom or LZDoom specifically -- "will not work with other
  engines"** (recent versions dropped plain GZDoom support entirely).
  This happens to already match this repo: `Doom/wad/default.nix`'s
  `mkDoom` already launches via `pkgs.uzdoom`.
- **Legacy of Rust / id Deathmatch (`id1`/`id1-res`/`id24res`/`iddm1`)**:
  supported by both tools -- WadFusion is actually the origin of that
  ZScript, wadsmoosh-plus added equivalent support independently.
- **"Master Levels Rejects" -- wadsmoosh-plus has no equivalent at all.**
  15 specific maps submitted as candidates for the original 1995 Master
  Levels but not selected (`cpu.wad`, `device_1.wad`, `dmz.wad`,
  `cdk_fury.wad`, `e_inside.wad`, `hive.wad`, `TWM01.WAD`, `MINES.WAD`,
  `anomaly.wad`, `FARSIDE.WAD`, `TROUBLE.WAD`, `DANTE25.WAD`,
  `ACHRON22.WAD`, `CABALL.WAD`, `UDTWiD.wad`), all with confirmed MD5s in
  WadFusion's README, all findable on idgames -- real historical content,
  genuinely absent from wadsmoosh-plus. WadFusion also uniquely supports
  John Romero's `e1m8b.wad`/`e1m4b.wad`, his own warm-up remakes for the
  cancelled *Blackroom*.
- **Community megawads (TNTR/PL2/PRCP/Doom Zero/Hell to Pay/etc.) are
  explicitly out of scope for WadFusion**, by the same design stance as
  the original -- this is the one thing wadsmoosh-plus still uniquely
  covers. Third-party unofficial addon layers exist for WadFusion too
  (`Someguyman/WadFusion-Unofficial-Xtras` bolts on Lost Episodes/
  Perdition's Gate/Hell to Pay/Freedoom/TNTR/PL2 as a separate mod, not
  baked into the core tool), but that's a different shape than
  wadsmoosh-plus's built-in support.
- WadFusion's README independently confirms, straight from the author:
  *"[KEX/Unity IWADs] can be used as the main IWADs for extraction, but
  do keep in mind that they are censored"* -- corroborating the red-cross
  finding earlier in this doc from an authoritative source, not just
  Steam forum posts. Its own recommended-source table also cross-checks
  useful details already established above: it sources `doom`/`doom2`/
  `tnt`/`plutonia` from GOG/Steam's **(DOS)** build specifically (the
  classic pre-KEX branch), matching MD5s already pinned in this doc
  (`1cd63c5d...` for doom.wad, `25e1459c...` for doom2.wad), while
  sourcing `masterlevels`/`nerve`/`sigil`/`sigil2`/`id1`/`extras` from
  the **(KEX)** build -- i.e. WadFusion is designed to mix old-DOS-branch
  core wads with new-KEX-branch bonus content by default, not requiring
  one homogeneous source, which lines up with (and cross-confirms) this
  doc's own per-wad sourcing plan above.

Given this doc already committed to fetching every community megawad
wadsmoosh-plus supports, wadsmoosh-plus stays necessary for that goal --
WadFusion won't do it. But WadFusion looks like the better choice
specifically for "best possible experience of the official content,"
given its active maintenance, Rejects/Blackroom-levels content nothing
else has, and deeper feature set. Worth building as a second, separate
`games.doom.wads` entry/`mkDoom` shortcut alongside the wadsmoosh-plus
output, not a replacement for it -- same shape as every other IWAD
variant this repo already exposes side by side.

**Revised recommendation, matching the actual planned use case (the
"Doom infinite roguelike stack" section below, not "expose every IWAD
variant as its own shortcut"): make WadFusion the primary base, not
wadsmoosh-plus.** The roguelike stack's own `build_dynamic.py` mechanism
(re-indexes arbitrary WAD map sets into new `MAPnn` slots after the base
IWAD's last slot) doesn't need wadsmoosh-plus's or WadFusion's own
per-wad texture/music-extraction machinery at all -- every community
megawad in this doc's list (Perdition's Gate, Freedoom, TNTR, PL2, Doom
Zero, PRCP, NEIS, Hell to Pay, Lost Episodes, `tnt2_beta6`) is just a
standalone level-replacement WAD, and can be fed straight into that
map-shuffle pool as "more maps," sourced from the primary locations
already established in this doc (idgames/ModDB/Bethesda/archive.org),
rather than needing either merge tool's bespoke per-wad support for them
specifically. That removes the main reason wadsmoosh-plus's broader
`WADS` list mattered in the first place -- WadFusion's official-content
depth (Rejects, Blackroom levels, active maintenance, matches this
repo's existing UZDoom launcher) becomes the deciding factor instead of
a secondary bonus.

Two addon repos worth checking before committing to that shape --
**turns out neither is clean, though for different reasons:**

- **`Someguyman/Wadfusion-Xtras`** (base repo, no typo) -- **correction
  from an earlier draft of this doc, which took its "(With Permission)"
  README claim at face value without checking the actual repo contents.
  Checked now (`Maps/`, `Graphics/Games/Doom 64 For Doom 2/`,
  `Sprites/Monsters/D64/`, `Sprites/Weapons/D64D2/`,
  `Flats/D64D2/*.raw`, `Sounds/Doom 64 Doom 2/*.lmp`, `Music/Doom 64 for Doom 2/*.mid`) via the GitHub contents API, not just the README prose:
  this repo directly checks in pre-extracted Doom 64 game assets** --
  real MIDI renditions of Doom 64's actual soundtrack (`D_BELLS.MID`,
  `d_watchr.mid`, etc, named after Doom 64's own track names), raw flat/
  texture data (`Flats/D64D2/*.raw`), and WAD-format sound effect lumps
  (`Sounds/Doom 64 Doom 2/dsmothac.lmp` etc, named after Doom 64-specific
  monster sounds) -- not a script that builds this from a legitimately-
  owned copy of the game at build time, the same shape `doom_i_ii.nix`
  already uses for the actual retail Doom/Doom II content. Doom 64 is
  still a commercially-sold game today (id Software's 2020 remaster, on
  Steam/GOG/consoles) -- "with permission" for redistributing its actual
  assets would mean permission from id/Bethesda specifically, a much
  bigger claim than a hobbyist repo's one-line README assertion can
  really substantiate. The repo's own top-level `README.md` undercuts its
  own permission claim further: *"In case anyone finds the sources for
  certain things, please let me know so that I can add them to the
  credits lump"* -- someone with genuine, documented permission from a
  rights holder wouldn't need the community's help figuring out what to
  credit. **Verdict reversed from the earlier draft: this fails the same
  provenance bar this doc has held everywhere else (Perdition's Gate's
  actual rights-reversion statement, Hell to Pay/Lost Episodes' vetted
  archive.org hosting) -- don't use this repo as a fetch source.** If
  Doom 64 content specifically is wanted later, the legitimate path is
  the same one `doom_i_ii.nix` already uses for retail Doom: require the
  user's own purchased copy (Doom 64 is on GOG/Steam) and extract/convert
  at build time, not pull pre-extracted assets from a third party.

- **`Someguyman/WadFusion-Unoffical-Xtras`** (note: genuinely misspelled
  in the real repo name -- "Unoffical," easy to mistype/confuse with the
  base repo above) -- **not a build tool, pre-extracted copyrighted game
  assets checked directly into a public repo**: individual per-map
  `.wad` files, full `Maps/`/`Sounds/`/`Sprites/`/`Graphics/` trees, for
  Lost Episodes of Doom, Perdition's Gate, Hell to Pay, Freedoom, TNT:
  Revilution, Plutonia 2, and Doom Zero -- with the *entire* licensing
  statement being one line: *"All rights go their respective authors."*
  No permission story, no rights-reversion documentation, nothing. For
  the confirmed-freeware titles in that set (Perdition's Gate/Freedoom/
  TNTR/PL2/Doom Zero) this doesn't add real legal risk since clean
  primary sources for all of them are already established above -- but
  it's still less traceable/reproducible than fetching from those
  primary sources directly. **For Hell to Pay and Lost Episodes of Doom
  specifically, this fails the "only from a site I've actually vetted as
  safe" bar already set for those two titles** -- a personal GitHub repo
  repackaging extracted retail assets with no permission documentation is
  a strictly worse provenance than archive.org's neutral, non-dark,
  direct-zip hosting already identified for both. Don't use this repo as
  the fetch source for either; keep the archive.org route, and feed them
  into `build_dynamic.py`'s map pool the same way as every other
  community megawad instead of trying to wire them through either merge
  tool's own extraction machinery.

  **Checked for a from-source build script and confirmed there isn't
  one**: Someguyman's full GitHub repo list (7 repos) has no separate
  build-tool companion; `WadFusion-Unoffical-Xtras`'s entire 58-commit
  history starts with pre-extracted content already in place at its very
  first commit (Nov 2024) -- never a source-based generator that later
  lost its scaffolding, always directly-committed assets; and a
  repo-name search across all of GitHub for "wadfusion" turns up only 4
  repos total, no independent third party has built an equivalent
  from-source tool either. Doesn't matter in practice, though: the
  `build_dynamic.py` map-shuffle-pool integration this content is
  actually headed for (see the roguelike-stack section below) just needs
  raw map lumps to renumber and append -- no merge-tool-style per-wad
  extraction step is needed for that use case at all, so there's nothing
  to reconstruct.

**Reversed: `Wadfusion-Xtras` is out of scope for the WadFusion build.**
Neither addon repo clears this doc's own provenance bar -- the
Doom-64-for-Doom-II port has no home to fetch from until either a real
from-source path (own the game, extract at build time) gets built, or
someone documents actual redistribution rights for the bundled assets.
Not blocking the rest of the WadFusion build, just means this specific
bonus feature stays unimplemented for now.

### WadFusion does real content checks -- confirmed by reading its source, not just wadsmoosh's

Since WadFusion is now the planned base (see "Revised recommendation"
below), worth checking whether its validation story is actually better
than wadsmoosh's -- it is, partially. `wadfusion.py` uses the same
`omgifol` library to open each candidate file and check for specific
marker lumps that only exist in one variant: `SKULA1` (registered vs
shareware Doom), `M_EPI4` (the episode-4 menu graphic, present only in
Ultimate Doom's 4 episodes), `INTERPIC` (flags a Unity/KEX `nerve.wad`),
`M_DOOM` (flags a KEX-era PWAD), `WATERMAP` (flags a KEX-era
`extras.wad`). So a wrong file renamed to `doom.wad` still gets *found*
by filename (same lookup mechanism as wadsmoosh), but functions like
`doom_is_retail()` will correctly report it as neither registered nor
retail rather than silently trusting the name. There's also real
completeness checking wadsmoosh entirely lacks --
`masterlevels_is_complete()` verifies every individual Master Levels
file is present before attempting the merge, with per-file verbose error
messages naming exactly what's missing, plus adaptive fallback (if Final
Doom is present without `doom2.wad`, it extracts shared resources from
`tnt`/`plutonia` instead, with a logged warning) -- genuinely smarter
than wadsmoosh's silent-partial-output failure mode.

What it still doesn't do: cryptographic hash verification. Marker-lump
presence can correctly identify *which variant* a file is and catch
*missing* files, but can't catch a corrupted download or a
tampered/wrong file that happens to carry the right marker lump for its
detected variant. So WadFusion's checks are a real second, independent
signal worth cross-referencing against this doc's own planned
size/lump-count/MD5 validation table below -- not a replacement for it.

### WadFusion's recommended-source table checked against wadsmoosh's -- three concrete differences

Read `Owlet7/wadfusion`'s actual README table directly (not just its
prose) and diffed it against wadsmoosh-plus's own "Where to find each
wad file?" section and this doc's own hash table above. Three real
differences that change what Phase 1 of the implementation plan below
actually needs to fetch -- not just "same content, different tool":

1. **Master Levels: WadFusion accepts the combined KEX `masterlevels.wad`
   as-is** (MD5 `ab3ce78e085e50a61f6dff46aabbfaeb`, sourced "GOG/Steam
   (KEX)") -- unlike wadsmoosh-plus, which needs the ~21 individually-
   named classic files copied into `source_wads/` separately (the
   "structural problem" flagged earlier in this doc). That mismatch is a
   wadsmoosh-plus-specific requirement, not a WadFusion one -- the
   already-fetched `rerelease/masterlevels.wad` in `doom_i_ii.nix` needs
   no splitting for the WadFusion build.
1. **Sewers/Betray: WadFusion wants the exact same corrected
   `SEWERS.WAD`/`BETRAY.WAD` this repo already fetches today.** Checked
   by direct MD5 against the `xboxspec.zip` copy already downloaded
   during earlier research (`md5sum` on the actual extracted files, not
   assumed): WadFusion's table lists `7b30cba8c9a79405a7240fd68eb013a5`
   for Sewers and `2bb99c282627b58ef3c753a9544255b9` for Betray -- both
   match the real files exactly. That's the opposite of wadsmoosh-plus's
   README, which points at idgames' raw `sewers2` (confirmed earlier in
   this doc to be MD5-identical to the *flawed* `SEWERSXB.WAD`, not the
   corrected file). So the earlier "switch `getFile` to `SEWERSXB.WAD`"
   fix in this doc was a wadsmoosh-plus-only correction -- for the
   WadFusion build (the actual plan target now), `doom_i_ii.nix`'s
   current `getFile "SEWERS.WAD" xboxspec` / `getFile "BETRAY.WAD" xboxspec` calls are already exactly right, no change needed there.
1. **WadFusion doesn't ask for the Unity-branch or BFG-Edition variants
   of `doom`/`doom2`/`tnt`/`plutonia` at all** -- its table sources all
   four from "GOG/Steam (DOS)" only (i.e. the `base/` folder), listing
   Unity/KEX IWADs only as a fallback ("can also be used... but do keep
   in mind that they are censored"). The "fetch every variant, trust the
   tool" strategy earlier in this doc was scoped to wadsmoosh-plus's own
   per-variant special-casing (`doomunity`/`doom2bfg`/etc as distinct
   simultaneous inputs) -- WadFusion has no equivalent mechanism, so
   Phase 1 below only needs one version of each: `base/` for the core
   four, KEX `rerelease/` for the bonus content. The Unity-branch/BFG
   fetches from that earlier strategy aren't wasted if wadsmoosh-plus
   ever gets built too, just no longer required for WadFusion itself.

New content confirmed in the same pass, not previously in this doc:
`iddm1.wad` and `extras.wad` both live in the same already-fetched KEX
`rerelease/` folder (two more `getFile` calls, no new fetcher needed);
`e1m8b.wad`/`e1m4b.wad` (Romero's Blackroom warm-up remakes) are on
idgames (`levels/doom/Ports/d-f/e1m8b`, `.../e1m4b`) with hashes matching
WadFusion's table exactly; an optional upgraded Sigil/Sigil II pair
(`SIGIL_V1_23_REG.wad` with the Buckethead remix baked in,
`SIGIL_II_MP3_V1_0.WAD` with THORR) is available straight from
`romero.com/sigil`, distinct filenames from the itch.io release this doc
considered earlier for wadsmoosh-plus.

### Confirmed: wadsmoosh does zero content validation

Read the actual fork logic (`wadsmoosh.py`/`wadsmoosh_data.py` on
`vanessakindell/wadsmoosh-plus`), not just its docs, to be sure: filename
matching is case-insensitive-exact and that's it --

```python
def get_wad_filename(wad_name):
    wad_name += '.wad'
    for filename in os.listdir(SRC_WAD_DIR):
        if wad_name.lower() == filename.lower():
            return SRC_WAD_DIR + filename
```

No checksum, byte-size, or lump-count check on any input, with exactly one
exception: it peeks for a BFG-Edition-only graphics lump to pick which
`doom2_secret_levels.txt` mapinfo variant to emit. Everything else is
"file with the right name showed up, use it." This confirms the concern in
this doc's earlier draft was correct and not paranoia -- the validation
layer genuinely has to be built here, wadsmoosh will not catch a
wrong-version or corrupted input on its own.

### The wads this repo already fetches are the wrong ones

This is the load-bearing finding: `Doom/wad/doom_i_ii.nix` fetches
`doom`/`doom2`/`tnt`/`plutonia`/`nerve`/`masterLevels`/`sigil`/`sigil2`/`id1`
from Steam appId 2280 (depot 2281) under `rerelease/*.wad` paths. That
`rerelease/` prefix is not incidental -- it's the 2024-08-08 KEX-engine
"Doom + Doom II" relaunch (Bethesda replaced the old DOSBox-based Unity
port with a new engine, id24 spec, and Legacy of Rust as a new episode),
and it produced **different files**, not re-releases of the same bytes.
Cross-checked against DoomWiki's per-IWAD hash tables:

| WAD | v1.9 classic (what wadsmoosh wants) | 2024-08-06 KEX rerelease (what we fetch today) |
|---|---|---|
| `doom.wad` (Ultimate, "1.9ud") | 12,408,292 bytes, 2,306 entries, MD5 `c4fe9fd920207691a9f493668e0a2083` | 12,733,492 bytes, 2,308 entries, MD5 `4461d4511386518e784c647e3128e7bc` |
| `doom2.wad` (v1.9) | 14,604,584 bytes, 2,919 entries, MD5 `25e1459ca71d321525f84628f45ca8cd` | 14,802,506 bytes, 2,928 entries, MD5 `9aa3cbf65b961d0bdac98ec403b832e1` |

(there was a second KEX revision on 2024-10-01 with yet another pair of
hashes -- Steam auto-updates in place, so whichever manifest gets pinned
matters, but both post-Aug-2024 revisions are equally wrong for wadsmoosh's
purposes.) Neither `atsb/WadSmoosh`'s README nor `wadsmoosh-plus`'s
`WADS` list (`doom`, `doom2`, `doom2bfg`, `tnt`, `plutonia`, `nerve`,
`sigil`, `sigil_shreds`, `sigil2`, `doomunity`, `doom2unity`, `nerveu`,
`tntu`, `plutoniau`, `extras`, `id1`, `id1-res`, `id24res`, plus the
freeware/community entries below) recognizes a KEX-format `doom.wad`/
`doom2.wad`/etc at all -- the closest it gets is `doomunity`/`doom2unity`,
which is the *older* pre-2024 Unity port, itself a third distinct set of
hashes, still not what a KEX-era Steam depot serves by default today.

Net effect: of the nine id-software wads `doom_i_ii.nix` currently
registers, **eight are unusable as wadsmoosh input as fetched** (`doom`,
`doom2`, `tnt`, `plutonia`, `nerve`, `masterLevels`, `sigil`, `sigil2`).
The one exception is `id1.wad` (Legacy of Rust) -- it was born as a
KEX-era file with no earlier "classic" version to be a mismatch *of*, and
`wadsmoosh-plus` explicitly lists `id1`/`id1-res`/`id24res` as real,
intentional input names. That one wires in as-is.

`masterLevels` has a second, structural problem on top of the version
mismatch: `doom_i_ii.nix` fetches it as a single combined
`rerelease/masterlevels.wad`, but wadsmoosh(-plus) wants the classic
release's ~21 individually-named WAD files (`attack.wad`, `canyon.wad`,
`catwalk.wad`, `combine.wad`, `fistula.wad`, `garrison.wad`, `manor.wad`,
`paradox.wad`, `subspace.wad`, `subterra.wad`, `ttrap.wad`, `virgil.wad`,
`minos.wad`, `bloodsea.wad`, `mephisto.wad`, `nessus.wad`, `geryon.wad`,
`vesperas.wad`, `blacktwr.wad`, `teeth.wad`, `teeth2.wad`) copied into
`source_wads/` directly -- a genuinely different input shape, not just a
version to re-pin.

### Strategy: fetch every variant wadsmoosh-plus recognizes, not just one

Given `wadsmoosh-plus` treats `doom`/`doom2bfg`/`doomunity` (and the
`tnt`/`plutonia`/`nerve` equivalents) as *distinct, simultaneously-valid*
input names rather than alternatives to pick one of, the plan is: fetch
every variant we can legitimately obtain -- regular/v1.9 (`base/` folder),
Doom 3: BFG Edition, and the Unity-port beta branch -- and register all
of them as source_wads inputs at once, even where that's redundant.
There's real precedent for trusting wadsmoosh's own per-variant logic to
do something useful with the overlap rather than just picking one and
discarding the rest: it already special-cases exactly this (the
BFG-only-lump check from the "confirmed: zero content validation"
section above exists *specifically* to pick a different
`doom2_secret_levels.txt` mapinfo variant when a BFG-flavored file is
present) -- so more inputs plausibly means more of these per-variant
special cases fire, not just wasted bytes. Worth sanity-checking once the
tool actually runs (does having both `doom2` and `doom2bfg` present
produce something different/better than either alone, or does one just
silently win?), but "fetch everything, trust the tool" is a reasonable
default regardless -- worst case redundant data is harmless, and the
validation layer below still needs a table entry per variant either way
since DoomWiki already publishes separate hashes for v1.9/BFG/Unity-port
builds of each of these (seen already in the `doom.wad`/`doom2.wad`
tables above).

### Where the right-version files actually come from

No manifest archaeology needed -- confirmed via two Steam community
threads (a Jan 2025 PSA and the launch-week "I Lost Ultimate Doom"
thread), not assumption: the classic files ship **in the same current
depot install**, right next to `rerelease/`, in a sibling `base/` folder.
Direct quote: *"In the 'rerelease' folder... they're updated versions
with some bugfixes and changed graphics (like the red cross on health
kits being changed to green). If you want the original files with no
changes, those are in the 'base' folder. Every commercial wad is there
except NERVE."* -- and a second commenter confirms Master Levels,
Plutonia, TNT, and Doom II are all present in `base/` too, "not missing,
just rearranged." That red-cross detail is a real, concrete instance of
exactly the censorship pattern flagged in the original ask, not a
hypothetical.

Practical upshot: `doom_i_ii.nix`'s existing `DOOM_I_II` derivation
(`fetchSteam { appId = 2280; depotId = 2281; manifestId = ...; filelist = wadFilter; }`) already fetches this depot with a `*.wad`-matching
filelist, which by its own regex (`(.*\.(wad|WAD))`, no path anchor)
already matches recursively -- `base/doom.wad` is very likely *already
sitting in that derivation's output today*, just never exposed via a
`getFile "base/..."` call. Confirming exact filenames (`DOOM.WAD` vs
`doom.wad` casing, whether `base/`'s Master Levels is the classic ~21
separate files or one combined file) just needs listing that folder once
-- either by building/inspecting the already-defined `DOOM_I_II`
derivation, or against a real local install if Steam's `base/` layout
matches what the community threads describe (this repo's own `conf.nix`
already points `IWADSearch.Directories` at
`.../Ultimate Doom/base`/`.../Doom 2/base`, so this was already assumed
to exist for local installs, just never wired into the fetcher). No new
fetcher code, no SteamDB, no beta-branch pin -- just additional
`getFile "base/<name>.wad" DOOM_I_II` calls once the exact names are
confirmed.

**NERVE (No Rest for the Living) is the one confirmed `base/` exception**
-- not present there at all, only in `rerelease/`. Per the fetch-every-
variant strategy above, this repo wants both of the following as
separate, simultaneous inputs, not a pick-one decision:

- **The Steam beta branch** ("Previous re-release 2019 version", still
  live per the launch-week thread -- Properties → Betas → Beta
  Participation), covering `doomunity`/`doom2unity`/`nerveu`/`tntu`/
  `plutoniau` as a homogeneous Unity-port set. Steam beta branches
  typically carry their own distinct `depotId` (not just an alternate
  manifest within the current depot), which is the normal case
  `fetchSteam { depotId; manifestId; }` already handles with zero fetcher
  changes -- just needs that branch's own depot/manifest IDs off SteamDB,
  same one-time lookup as every other pinned `fetchSteam` call in this
  repo, not a new code path.
- **Doom 3: BFG Edition** (appId 208200), covering `doom2bfg` (and its
  own `doom`/`nerve` variants) as a further distinct input -- never
  bundled `tnt`/`plutonia`/Master Levels/Sigil, so doesn't stand in for
  those, but adds another legitimately-different `nerve.wad` on top of
  whatever the Unity branch provides.
- **GOG** via the existing `fetchGOG`, not investigated -- lowest
  priority, only relevant if a gap turns up that Steam can't cover.
- **Sigil / Sigil II** are the one case worth *not* extracting from any
  Steam depot at all: they're free John Romero releases distributed
  independently (`sigil.wtf`, `romerogames.itch.io`), and
  `wadsmoosh_data.py` explicitly whitelists the official release's own
  filenames as accepted alternates (`sigil_v1_0.wad`, `sigil_v1_1.wad`,
  `sigil_v1_2.wad`, `sigil_v1_21.wad` for Sigil; `sigil_ii_v1_0.wad`,
  `sigil_ii_mp3_v1_0.wad` for Sigil II) -- fetching the original freeware
  release directly (probably itch.io, `lib/fetchers/itch.nix` already
  covers that host) is simpler than chasing a Steam-bundled copy and
  avoids the KEX mismatch for these two entirely.
- **Xbox secret levels** (`sewers.wad`/`betray.wad`): already sourced from
  `classicdoom.com`'s `xboxspec.zip` fan-restoration project in
  `doom_i_ii.nix` today -- this is specifically the known-good
  PC-compatible reconstruction wadsmoosh's own docs point at, so likely
  already correct as-is; still needs a pinned expected hash in the
  validation table below rather than being assumed fine by inspection.

### Validation layer

Once real per-wad expected values are collected (only `doom.wad`/
`doom2.wad` are pinned above -- `tnt`, `plutonia`, `nerve`, `sigil`,
`sigil2`, `sewers`, `betray`, and all ~21 Master Levels files still need
their own DoomWiki-table lookup before this can be written), the shape is:
a small checked-in Nix table (`{ expectedSize, expectedEntries, md5 }` per
wadsmoosh input name, values sourced from DoomWiki), and a build step that
computes each fetched file's real size/lump-count/MD5 and asserts it
against the table *before* the file is copied into `source_wads/`. Same
wrinkle called out before: this repo's fetchers pin `sha256`/NAR-mode
`outputHash`, DoomWiki publishes MD5 -- the check has to run against the
WAD's own bytes at build time (cheap: size and lump-count alone, both in
DoomWiki's tables, catch a wrong-version file without needing an MD5
implementation at all; MD5 as a stronger second check if wanted). One
change from the earlier draft of this plan: a wad that's present but
fails validation should **hard-fail the build**, not be silently
skipped/omitted -- these are all supposed to be present, and a silently
short `doom_complete.pk3` missing an episode is a much worse debugging
experience than a loud build failure naming exactly which file didn't
match.

Not a `mkModDir`-shaped problem -- wadsmoosh consumes a small fixed set of
known input files to produce one transformed output file, not a directory
tree an engine reads directly, so it doesn't need a generic mod-merging
helper, just a plain build step with a validated `source_wads/` input.

**Correction from an earlier draft of this doc**: the classic-format wads
this needs should still land in the shared `games.doom.wads` registry,
not stay as private `let`-bound fetches -- there's no actual registry
name clash to avoid, because `doom`/`doom2` (and, by the same reasoning,
`tnt`/`plutonia` -- flagged as an open question below) get *repointed* at
the classic `base/` files rather than living alongside a second,
differently-named copy. Every other existing `mkDoom` game entry that
currently consumes `doom`/`doom2`/`tnt`/`plutonia` (`DOOM`, `DOOM_2`,
`NERVE`, `MASTER_LEVELS`, `SIGIL_I`, `SIGIL_II`, `PLUTONIA`, `TNT`, `ID1`
in `doom_i_ii.nix`) switches to the classic version too, which is a
strict improvement for all of them (no more red-cross-style censorship),
not just a WadFusion-only concern.

`wadsmoosh-plus` itself isn't a package anywhere -- it's a plain script
repo, no PyPI listing -- so it needs `fetchFromGitHub` at a pinned rev
(same `fetchGitTree` shape `freedoom.nix` already uses for
`blasphemer`/`lastermaul`), run directly with `pkgs.python3`. Its actual
CLI entrypoint, output path, and whether it needs anything beyond the
stdlib haven't been checked yet -- next thing to look at before writing
the derivation.

### Wires into

`doom_complete.pk3` is meant to be used as an `-iwad`, per this doc's own
"Doom infinite roguelike stack" section below -- so the real wiring point
is a new `games.doom.wads.wadsmoosh` entry usable as `iwad` in a `mkDoom`
call, not the dead `doom.id.wadsmoosh`/`doom.id.doom2.wadsmoosh`
`*.Autoload` categories in `conf.nix`, which are the wrong shape for an
IWAD and look like a placeholder that was never reconciled with how this
would actually get consumed -- worth cleaning those up rather than
stuffing `doom_complete.pk3` into them just because the names line up.

### Full `wadsmoosh-plus` `WADS` list, cross-referenced against this repo

Pulled straight from `wadsmoosh_data.py`'s `WADS` array and the fork's own
README "Where to find each wad file?" section (which turns out to name an
actual source, or explicitly say "retail release, find your own copy,"
for nearly every entry -- no more guessing needed for most of these).
Three buckets:

**Already have the underlying fetch, just needs wiring:**

- `id1`, `id1-res`, `id24res`, and (per the README, previously missed)
  `iddm1` -- README confirms all four come "from the KEX-based
  re-release," i.e. exactly `DOOM_I_II`'s `rerelease/` path that
  `doom_i_ii.nix` already fetches. Only `id1.wad` is currently wired to
  `getFile`; `id1-res.wad`/`id24res.wad`/`iddm1.wad` are sitting in the
  same already-fetched derivation, just need three more `getFile` calls.
- `freedoom1`/`freedoom2` -- already fetched (`freedoom.nix`, via
  `pkgs.freedoom`) for unrelated purposes. README asks for v0.13.0
  specifically; worth confirming `pkgs.freedoom`'s pinned version matches
  before wiring it in, since (per the earlier finding) wadsmoosh won't
  itself notice a mismatch.
- `doom`/`doom2`/`tnt`/`plutonia` (regular v1.9-ish) -- via `base/` in the
  already-fetched `DOOM_I_II` depot, per the earlier section.
- `doomunity`/`doom2unity`/`extras`/`nerveu`/`tntu`/`plutoniau` -- via the
  Steam beta branch, per the earlier section. (The README's own
  instructions for these -- pull `doom.wad`/`doom2.wad` out of the old
  Unity port's `rerelease/DOOM_Data/StreamingAssets/` and rename them --
  predate the 2024 KEX relaunch and describe the *old* Unity port's own
  folder layout, coincidentally also called `rerelease/`; don't confuse
  it with the KEX depot's `rerelease/` we've been discussing above, they
  are different builds under the same folder name.)

**Freely available, needs a new fetcher (idgames/moddb, both already
have fetchers in this repo):**

- **TNT: Revilution** (`tntr.wad`) -- confirmed via idgames link:
  `/idgames/levels/doom2/megawads/tntr`.
- **Plutonia 2** (`pl2.wad`) -- confirmed: `/idgames/levels/doom2/megawads/pl2`.
- **No End In Sight** (`neis.wad`) -- confirmed:
  `/idgames/levels/doom/Ports/megawads/neis`.
- **Doom 3DO Soundtrack** (`doom3do.wad`) -- confirmed:
  `moddb.com/games/doom/addons/doom-3do-music` -- `fetchModDB` already
  exists in this repo (`moddb.nix` uses it for several other wads).
- **Plutonia Revisited Community Project** (`prcp.wad`) -- confirmed live
  and downloaded: `/idgames/levels/doom2/Ports/megawads/prcp.zip`,
  containing `PRCP.wad` exactly as `wadsmoosh_data.py` expects (case-
  insensitive match). Ready to fetch via the existing `fetchIdGames`.
- **Perdition's Gate** (`perdgate.wad`) -- **not actually retail-only**,
  correcting the bucket below: rights reverted from WizardWorks back to
  the original creators in 2016 (per a public statement from co-creator
  Mustaine), making it legitimately freeware; also confirmed live on
  idgames (`/idgames/levels/doom2/p-r/pdgate.zip`). One real gotcha: the
  file inside is `Pdgate.wad`, not `Perdgate.wad` -- `wadsmoosh_data.py`
  looks for `perdgate.wad` case-insensitively, so this needs an explicit
  rename when copied into `source_wads/`, it won't match as-is.
- **Sigil / Sigil II** official releases -- README points to
  `romero.com/sigil` directly (not through Steam at all) -- matches this
  doc's earlier recommendation.

**Confirmed but needs a different fetcher than expected:**

- **Doom Zero** (`doomzero.wad`) -- turns out **not** to be on idgames at
  all (DoomWiki's own external-links list for it omits idgames entirely,
  and guessing common idgames paths for it 404'd) -- corrects an earlier
  guess in this doc. Real sources: ModDB (`fetchModDB` already exists in
  this repo) and Bethesda's own official add-on channel -- Doom Zero is
  one of the 22 titles on DoomWiki's `Category:Official_add-ons` list
  (freeware add-ons for the Doom Classic Unity port, distributed via
  Bethesda.net's "Slayers Club"), which independently confirms its
  freeware status even though it's not on idgames specifically. There's
  also an archive.org mirror of the full official-add-ons bundle
  (`archive.org/details/DOOM-Add-ons`, 22 numbered zips, not individually
  labeled) as a fallback if ModDB access is inconvenient.
- **TNT: Devilution** (`tnt2_beta6.wad`) -- **found**. idgames only has
  the current release (`TNT2_1_2.wad`), not the beta-6 snapshot
  `wadsmoosh_data.py` was written against, but the actual `TNT2_beta6.zip`
  turned up via a Wayback Machine capture of the original May 2023
  Doomworld release-announcement thread -- a Dropbox share link
  (`dropbox.com/s/xpq5v3bt300rqu6/TNT2_beta6.zip`) that's still live
  today. Downloaded and confirmed: contains `TNT2_beta6.wad` (74MB,
  dated 2023-05-10) and `tnt2_beta6.deh`, matching "the sixth and final
  beta" release date and exactly the filenames
  `wadsmoosh_data.py`/`WAD_LUMP_LISTS` expect -- no rename or guessing
  needed, unlike the idgames-current-release mismatch. Real caveat: this
  is a personal Dropbox share, not a stable archive host (idgames/ModDB/
  GitHub release) -- it can be revoked or changed with no warning at any
  time, unlike every other fetcher source in this repo. `pkgs.fetchurl`
  against the `?dl=1` link should work directly (it 302-redirects to a
  content URL and pins by hash regardless), but this one's worth a
  standing note in the fetcher itself that the URL is unusually fragile,
  and the Wayback capture of that thread is the fallback lead if it dies
  (the raw snapshot fetch attempt itself 403'd; worth retrying other
  capture timestamps at implementation time rather than assuming it's
  gone for good).

**Retail-only, but a legally-owned copy isn't the only option -- willing
to use vetted abandonware if it comes with a standing reminder to
replace it:**

- **Hell to Pay** (`hell2pay.wad`) and **The Lost Episodes of Doom**
  (`jptr_v40.wad`) -- unlike Perdition's Gate, no rights-reversion story
  turned up for either; both are WizardWorks-era commercial retail
  add-ons, publisher defunct since 2004, not on GOG/Steam/DoomWiki's
  22-title official-add-ons list. But there's a real safety gradient
  among "abandonware" sources worth distinguishing, not a flat "skip":
  **archive.org has direct, non-dark, plain-zip copies of both**
  (`Hell_to_Pay_1996.zip`, 48MB; `The_Lost_Episodes_of_Doom_1995.zip`,
  9.8MB) -- a non-profit host serving the raw file directly, no
  installer wrapper, no ad/redirect chain, categorically safer than the
  ad-supported abandonware aggregators (My Abandonware, Old-Games.com,
  DOS Games Archive) that also carry copies. Verdict: fetch these two
  from archive.org specifically, not the aggregator sites -- and per
  instruction, the fetcher for each needs a standing comment flagging it
  as an unlicensed-source stopgap, e.g. `# sourced from archive.org, no confirmed legal redistribution right -- replace with a legitimately- owned rip if a real copy of the disc ever turns up` -- so the
  provenance gap doesn't quietly become invisible once the derivation is
  written and working.
- **`doom2bfg`** and any other BFG-Edition-specific content -- needs an
  actual Doom 3: BFG Edition purchase (Steam appId 208200), already
  covered as a real-but-secondary source above, not "free" beyond
  already owning it.

**Sewers/Betray, actually checked byte-for-byte (not just cross-referenced
by link):** downloaded both `xboxspec.zip` and idgames' `sewers2.zip`
directly and compared. Result: `SEWERSXB.WAD` (the *flawed, raw Xbox*
level, inside the already-fetched `xboxspec.zip`) is **MD5-identical**
to idgames' `sewers2` -- `293240d48a1f924f4f8e91c0282f9fbd` on both. This
isn't a coincidence: the Xbox port's "Sewers" secret level was built
directly from David Calvin & David Blanshine's 1994 community PWAD of
the same name, confirmed by `xboxspec.zip`'s own included `XBOXSPEC.TXT`
history notes. So wadsmoosh's README linking to idgames for `sewers.wad`
means it wants the **flawed/raw** edition, not the "corrected, supersedes
earlier files" `SEWERS.WAD` that `classicdoom.com` recommends for actual
play and that `doom_i_ii.nix` currently fetches
(`getFile "SEWERS.WAD" xboxspec`). Fix: switch that `getFile` call to
`"SEWERSXB.WAD"` -- same already-fetched zip, no new fetcher, just a
different member.

Betray doesn't resolve as cleanly. The Doomworld "known lost wads" thread
(rescued from a Wayback Machine snapshot, since the live forum blocks
scripted fetches entirely) centers on a claimed "true 1995 original"
`Betray.wad` found on an old shareware CD, MD5
`b449ad1d43932287c19907790ef49a7d` -- and that hash matches **neither**
`xboxspec.zip`'s `BETRAYXB.WAD` (`589da6964b0148cce6472d3e3b9e8c29`) nor
its `BETRAY.WAD` (`2bb99c282627b58ef3c753a9544255b9`). All three are
different files. The thread's own archive.org preservation of that
"original" (`archive.org/details/betray_202209`) is now dark (taken
down), so there's no way to actually obtain and check it right now.
Working assumption -- unconfirmed, flagged as such -- is to follow the
same pattern as Sewers and use `BETRAYXB.WAD` (raw Xbox original) rather
than `BETRAY.WAD` (corrected), on the theory that Betray was likely also
built from a pre-existing PC PWAD the same way Sewers was; resolving this
for real needs either logged-in browser access to that Doomworld thread
or accepting the current uncertainty.

### Open items before implementation

In priority order: (1) confirm exact `base/` filenames/layout in the
already-fetched `DOOM_I_II` depot and fill the classic validation rows for
`doom`/`doom2`/`tnt`/`plutonia`; (2) complete the WadFusion input validation
table, including the chosen KEX bonus files and Xbox files; (3) inspect and
pin the WadFusion v1.6.1 release artifact and matching UZDoom variant; (4)
package and smoke-test DoomTools/WadMerge; (5) implement parser fixtures and
the collision/reference-rewrite policy; (6) obtain and test MOShuffle against
standalone generated maps, gaps, and explicit warp maps; (7) inspect and test
Vandomizer, Universal Entropy, and CorruptionCards independently; (8) resolve
the remaining provenance/hash details for the requested optional sources.
These are implementation gates, not reasons to keep expanding the research
appendix.

## Doom infinite roguelike stack

Builds directly on top of the WadFusion derivation above (revised from
an earlier draft of this doc that assumed wadsmoosh-plus's
`doom_complete.pk3` specifically -- see the "Revised recommendation"
note under WadFusion above for why): stack `doom_fusion.ipk3` as the
IWAD, then layer a dynamically-generated custom-map pack plus a
shuffler, universal spawn randomizers, and a roguelike mutator-card mod
on top, so every run is a random subset of maps in a random order with
randomized enemy/weapon placement and run-modifying "corruption cards"
each level. The custom-map pack is also where every community megawad
from this doc's wadsmoosh-plus section (Perdition's Gate, Freedoom,
TNTR, PL2, Doom Zero, PRCP, NEIS, Hell to Pay, Lost Episodes,
`tnt2_beta6`) actually plugs in -- as more source WADs fed to
`build_dynamic.py` below, not through WadFusion's or wadsmoosh-plus's
own per-wad extraction machinery.

```
┌─────────────────────────────────────────────────────────────┐
│                    GZDOOM LAUNCH STACK                      │
├─────────────────────────────────────────────────────────────┤
│ 1. doom_fusion.ipk3   (WadFusion base: Retail IWADs)        │
│ 2. custom_maps.pk3    (Merged custom + community-megawad    │
│                         maps: MAP172 → MAPnn)                │
│ 3. MOShuffle.pk3      (Shuffles all map slots each run)     │
│ 4. Weapon_Rand.pk3    (Universal weapon spawn pool)         │
│ 5. Monster_Rand.pk3   (Universal monster spawn pool)        │
│ 6. CorruptionCards    (Roguelike run mutators/cards)        │
└─────────────────────────────────────────────────────────────┘
```

**Map pool for the custom-map merge** -- scope is deliberately narrow:
only the community megawads already discussed for the wadsmoosh-plus/
WadFusion section, plus the Japanese one, both explicitly asked for.
An earlier draft of this doc added a much broader "well-regarded
Cacoward-caliber" idgames list (Scythe, Sunlust, Eviternity, Alien
Vendetta, BTSX, etc) on its own initiative during research -- that
wasn't something asked for, so it's been dropped. Every entry below
(going in as ordinary map WADs, not through either merge tool's own
extraction machinery, per the reframing above) was directly downloaded
and confirmed live during earlier research passes, same rigor as the
IWAD-piece sourcing above:

- Already-sourced from the wadsmoosh-plus/WadFusion research: TNT:
  Revilution (`tntr.wad`), Plutonia 2 (`pl2.wad`), Plutonia Revisited
  Community Project (`prcp.wad`), No End in Sight (`neis.wad`), Doom Zero
  (`doomzero.wad`), Perdition's Gate (`Pdgate.wad`), Hell to Pay
  (`hell2pay.wad`, via archive.org), The Lost Episodes of Doom
  (`jptr_v40.wad`, via archive.org), TNT 2: Devilution beta 6
  (`TNT2_beta6.wad`, via the Dropbox/Wayback link found earlier).
- **Japanese Community Project** (`JPCP.wad`) -- the "Japanese one":
  confirmed via research, not assumption -- a 32-level Doom II megawad
  made by a collective of over a dozen Japanese Doomworld community
  members, 2016 Cacoward winner. `idgames:levels/doom2/Ports/megawads/jpcp.zip`,
  confirmed live (45MB). Fetch just `JPCP.wad` -- skip the zip's optional
  `JPCP_HUD.wad` (Katakana/Kanji status bar replacement), not wanted.

If more megawads are wanted later, add them explicitly rather than
this doc re-expanding the list on its own -- the fetcher shape
(`fetchIdGames`/`fetchModDB`/archive.org `fetchurl`) is identical for
any additional idgames-hosted megawad, so nothing about Phase 3 below
would need to change structurally to add one.

**Freedoom texture-collision note for the merge script -- not yet
addressed anywhere in this doc's `build_dynamic.py` sketch, needs to
be**: Freedoom's maps use Freedoom's own texture set, which mirrors the
*same lump names* as the original retail Doom textures (deliberate, since
Freedoom is designed as a drop-in IWAD replacement). If Freedoom's
texture-definition lumps (`TEXTURE1`/`PNAMES`, or any Freedoom PWAD's own
texture-replacing patches) get merged into the shared pool the same way
Freedoom's *maps* do, they'll silently shadow the real Doom textures for
every map in the merged pk3, not just Freedoom's own -- because lump
resolution in a merged PK3/WAD is global, not per-map-namespaced, unless
the build script explicitly prevents it. `wadsmoosh-plus` already solved
exactly this for its own use case (per its README: it includes Freedoom's
"maps, music and *new* textures" but deliberately excludes "sprites nor
the Doom-replacing textures since they will use the original ones") --
`build_dynamic.py` needs the equivalent precaution: when pulling Freedoom
into the merged map pool, strip/skip its `TEXTURE1`/`PNAMES` and any
patch lumps that reuse original-Doom texture names, keeping only
Freedoom's actual map lumps plus whatever textures are genuinely new
(not name-colliding). Worth implementing as an explicit filter step in
the script, not left as an assumption -- a silent texture override would
be a subtle, hard-to-notice bug (everything still loads and plays, walls
just look wrong) rather than a loud failure.

**Map-merging build script** -- reads `doom_fusion.ipk3`/`.wad` to find the
highest existing `MAPnn` slot, then re-indexes an arbitrary number of separate
custom map WADs to start right after it. The actual WadFusion output is the
source of truth; there is no fixed `MAP33` assumption. The generated maps are
ordinary standalone `MAPnn` entries for MOShuffle, which changes `nextmap` and
`secretmap` at runtime. Do not add synthetic `next` links unless testing shows
the selected MOShuffle mode requires them. Inputs with explicit scripted warps
need separate handling because they can bypass MOShuffle.

The script needs `omgifol` (Python WAD library) and DoomTools' `wadmerge` on
`PATH`. WadMerge is a command-line utility, not a Python library:
https://mtrop.github.io/DoomTools/wadmerge.html.

```python
#!/usr/bin/env python3
import sys
import os
import re
import argparse
import subprocess
import zipfile
from omgifol import WAD

def get_next_available_map_index(base_wadfusion_path):
    map_numbers = []

    if base_wadfusion_path.endswith('.pk3') and zipfile.is_zipfile(base_wadfusion_path):
        with zipfile.ZipFile(base_wadfusion_path, 'r') as pk3:
            for filename in pk3.namelist():
                # Do not infer maps from arbitrary PK3 filenames. Inspect WAD
                # members and their actual map-marker lump sequences.
                if filename.lower().endswith(('.wad', '.iwad')):
                    map_numbers.extend(read_map_numbers_from_wad_member(pk3, filename))

    elif base_wadfusion_path.endswith('.wad'):
        src_wad = WAD()
        src_wad.from_file(base_wadfusion_path)
        for map_name in src_wad.maps:
            match = re.match(r'MAP(\d+)', map_name, re.IGNORECASE)
            if match:
                map_numbers.append(int(match.group(1)))

    if not map_numbers:
        raise ValueError(f"Could not detect numeric MAP entries in {base_wadfusion_path}")

    highest_map = max(map_numbers)
    next_slot = highest_map + 1
    print(f"[*] WadFusion highest slot detected: MAP{highest_map:02d}. Custom maps will start at MAP{next_slot:02d}.")
    return next_slot

def generate_wadmerge_auto(base_wadfusion_path, output_pk3, input_wads):
    start_index = get_next_available_map_index(base_wadfusion_path)
    script_filename = "auto_merge.txt"

    wadmerge_commands = [
        "# Auto-generated WadMerge Script starting dynamically after WadFusion",
        "create outwad",
    ]

    current_map_idx = start_index

    for wad_path in input_wads:
        src_wad = WAD()
        src_wad.from_file(wad_path)

        maps = src_wad.maps
        if not maps:
            print(f"Skipping {os.path.basename(wad_path)} (No maps found)")
            continue

        for orig_map in maps:
            new_map_slot = f"MAP{current_map_idx:02d}"
            wadmerge_commands.append(
                f"mergemapfile outwad {new_map_slot} {wad_path} {orig_map}"
            )

            current_map_idx += 1

    wadmerge_commands.append("finish outwad temp_merged_maps.wad")
    wadmerge_commands.append("end")

    with open(script_filename, "w") as f:
        f.write("\n".join(wadmerge_commands))

    print("\nExecuting WadMerge...")
    subprocess.run(["wadmerge", script_filename], check=True)

    print(f"Packaging into {output_pk3}...")
    with zipfile.ZipFile(output_pk3, 'w', zipfile.ZIP_DEFLATED) as pk3:
        pk3.write("temp_merged_maps.wad", arcname="maps/custom_maps.wad")

    if os.path.exists("temp_merged_maps.wad"):
        os.remove("temp_merged_maps.wad")
    if os.path.exists(script_filename):
        os.remove(script_filename)

    print(f"\n[+] Success! Packaged custom maps ranging from MAP{start_index:02d} to MAP{current_map_idx - 1:02d}.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Merge custom WAD maps dynamically starting after WadFusion's last map.")
    parser.add_argument("-b", "--base-wadfusion", required=True, help="Path to doom_fusion.ipk3 or doom_fusion.wad")
    parser.add_argument("-o", "--output", default="custom_maps.pk3", help="Output PK3 file name")
    parser.add_argument("wads", nargs="+", help="Input custom WAD files")

    args = parser.parse_args()
    generate_wadmerge_auto(args.base_wadfusion, args.output, args.wads)
```

Build + launch shape:

```sh
# build custom_maps.pk3 from N arbitrary map WADs, indexed after WadFusion's last slot
python build_dynamic.py -b doom_fusion.ipk3 -o custom_maps.pk3 mapset1.wad mapset2.wad mapset3.wad

# stack everything and launch
uzdoom \
  -iwad doom_fusion.ipk3 \
  -file custom_maps.pk3 \
        MOShuffle.pk3 \
        Vandomizer.pk3 \
        UniversalEntropy.pk3 \
        CorruptionCards.pk3
```

Run mechanics: MOShuffle builds a random order from conventional
`MAP01`-`MAPnn` maps and changes the next destination at runtime; the maps do
not need to be connected in advance. Maps with explicit scripted warps can
evade the shuffle. Vandomizer randomizes weapon/item and related spawns,
Universal Entropy randomizes monster properties, and Corruption Cards presents
configured cards per level. The exact permanent-card semantics must be tested
against the selected CorruptionCards release.

### Full implementation plan -- WadFusion derivation + map-fusion pipeline

Pulls together every finding above (this doc's WadFusion section and
this roguelike-stack section) into one ordered build sequence. Still a
plan, not code, per the original "don't implement" framing. The work is
split into independently testable vertical slices: source inputs, WadFusion,
one merged map pack, MOShuffle, and then each gameplay mod separately.
The implementation order is: (1) classic source registry and validation,
(2) WadFusion plus a plain launcher, (3) DoomTools/WadMerge and the parser
with fixtures, (4) one minimal generated map pack, (5) MOShuffle, (6)
CorruptionCards, (7) Vandomizer, (8) Universal Entropy, and only then the
complete map pool and final shortcut. Each layer must work before the next is
added. **Corrected from an earlier draft**: the
source wads all land in the shared `games.doom.wads` registry (not
private `let`-bound fetches), and every game entry (base WadFusion, the
roguelike stack, and every other piece already in `Doom/wad/`) is wired
up purely through `mkDoom`'s `iwad`/`wad` args and
`programs.steam.games` -- `Doom/conf.nix`'s `*.Autoload`/
`IWADSearch.Directories` mechanism is a different, orthogonal piece of
this repo (global path/autoexec config for the engine, not a per-game
content list) and isn't where any of this gets wired in.

**Phase 1 -- source-wad fetchers**, extending the existing
`doom_i_ii.nix` (and its already-fetched `DOOM_I_II`/`xboxspec`
derivations) rather than a separate file, since these are now real
registry entries, not private inputs:

1. **Repoint the classic inputs from `rerelease/` to `base/`** --
   intentionally change `doom`, `doom2`, `tnt`, and `plutonia` to their
   classic `base/` files. The current KEX files were mistakenly assumed to be
   classic; this is a deliberate correction and applies to existing consumers
   as well as WadFusion.
1. **Wire the classic Doom and Doom II files** -- the
   `games.doom.wads.doom`/`.doom2` keys `doom_i_ii.nix` already defines
   switch from `getFile "rerelease/doom.wad" DOOM_I_II` to `getFile "base/doom.wad" DOOM_I_II` (same for `doom2`), fixing every existing
   consumer (`DOOM`, `DOOM_2`, `NERVE`, `MASTER_LEVELS`, `SIGIL_I`,
   `SIGIL_II`, `ID1`) to the uncensored classic version, not just
   WadFusion. Confirm exact `base/` filenames/casing first. Apply the same
   intentional classic swap to the `tnt` and `plutonia` registry entries.
1. **KEX `rerelease/` content already fetched today** -- add `getFile`
   calls for `id1-res`, `id24res`, `iddm1`, and `extras` (four more pulls
   off the same already-fetched `DOOM_I_II` derivation, no new fetcher).
   `masterlevels` stays as the single combined KEX file already fetched
   -- **no splitting into ~21 files needed**, confirmed WadFusion accepts
   `masterlevels.wad` directly (see the three-differences section
   above); that splitting requirement was wadsmoosh-plus-specific.
1. **Xbox secret levels -- no change needed.** `doom_i_ii.nix`'s existing
   `getFile "SEWERS.WAD" xboxspec` / `getFile "BETRAY.WAD" xboxspec`
   calls already fetch exactly the files WadFusion's own table expects,
   confirmed by direct MD5 match (previous section) -- register them
   under `games.doom.wads` if not already (they already are).
1. **New content, not previously in this doc's fetch plan**: Master
   Levels Rejects' 15 wads (list + hashes already in this doc, all
   idgames except `caball.wad` which needs a plain `fetchurl` against
   `doomshack.org`), each its own
   `games.doom.wads.masterLevelsRejects*` entry. **`e1m8b.wad`/
   `e1m4b.wad` deliberately excluded here** -- see Phase 3 below: they
   *replace* E1M8/E1M4 rather than being purely additive, so they belong
   in the map-shuffle pool, not WadFusion's own source_wads.
1. **Optional upgrade, not required, and NOT free -- checked, both cost
   money**: Sigil/Sigil II's Buckethead/THORR variants
   (`SIGIL_V1_23_REG.wad`, `SIGIL_II_MP3_V1_0.WAD`). WadFusion's KEX
   `sigil.wad`/`sigil2.wad` (already fetched, already owned via
   Doom+Doom II) already satisfies its recommended table on their own --
   this is a nice-to-have, not a gap, and given the cost, not worth
   pursuing unless specifically wanted. **Purchase required**: `SIGIL with Buckethead Soundtrack` -- €6.66,
   `romero.com/shop/p/sigilbuckethead`; `SIGIL II with THORR soundtrack`
   -- €6.66, `romero.com/shop/p/sigil-ii-thorr` (the base MIDI-only
   SIGIL/SIGIL II, already covered via the KEX depot above, are free --
   only these specific upgraded bundles cost anything). See "Purchase-
   required items" below.
1. **Not required for WadFusion specifically** (kept only if
   wadsmoosh-plus itself ever gets built separately, per the "revised
   recommendation" above): the Steam beta branch's Unity-port wads
   (already owned -- same appId 2280 depot as the base Doom+Doom II
   purchase, just a different branch, no new purchase) and Doom 3: BFG
   Edition's `doom2bfg`. **Purchase required for BFG Edition** -- Steam
   appId 208200, not currently owned/registered anywhere in this repo.
   WadFusion's own recommended-source table doesn't ask for either (see
   the three-differences section above), so these drop out of the
   WadFusion critical path regardless of purchase status. See "Purchase-
   required items" below.
1. `freedoom1`/`freedoom2` -- already fetched via `pkgs.freedoom`,
   already registered; confirm the pinned version matches WadFusion's
   expected v0.13.0 before reuse.
1. Validation table -- per-wad `{ expectedSize; expectedEntries; md5; }`
   sourced from DoomWiki's hash tables (WadFusion's own README table
   above already supplies several of these MD5s directly), asserted
   against each fetched file's real bytes at build time, hard-failing on
   a mismatch. WadFusion's own marker-lump checks (`SKULA1`/`M_EPI4`/
   `INTERPIC`/`M_DOOM`/`WATERMAP`, plus `masterlevels_is_complete()`) are
   a genuine second signal, not a substitute for this table.

**Phase 2 -- the WadFusion derivation itself, and two game entries:**

9. Add the selected WadFusion release to `sources.toml` with
   `update-sources.py --append`, then fetch the pinned release/tree through
   the repository's existing source mechanism. The current upstream release
   target is v1.6.1: https://github.com/Owlet7/wadfusion/releases/tag/v1.6.1.
   Inspect the release archive before choosing `fetchGitTree` versus the
   release artifact; pin the exact script, data files, `omgifol` dependency,
   and matching UZDoom variant together. **No `Wadfusion-Xtras` entry** --
   reversed above, its Doom 64 content doesn't clear this doc's provenance
   bar.
1. Build from a named input attrset rather than a positional list. Inputs
   correspond to WadFusion's logical source names (`doom`, `doom2`, `tnt`,
   `plutonia`, `nerve`, `masterlevels`, `sigil`, `sigil2`, `id1`, and so on).
   Supported but unavailable inputs are `null`; required null inputs fail
   clearly, while optional null inputs are omitted from the invocation.
   The derivation interface should have this shape (with the complete
   upstream-supported set filled in during implementation):
   ```nix
   wadfusion = mkWadFusion {
     doom = doomClassic;
     doom2 = doom2Classic;
     tnt = tntClassic;
     plutonia = plutoniaClassic;
     nerve = nerve;
     masterlevels = masterLevels;
     sigil = sigil;
     sigil2 = sigil2;
     id1 = id1;
     id1Res = id1Res;
     id24res = id24res;
     iddm1 = iddm1;
     extras = extras;
     # Supported, but not available in this checkout:
     someOptionalInput = null;
   };
   ```
1. Register the result as `games.doom.wads.wadfusion` in the shared
   registry, same as every other entry.
1. **Two separate game entries**, both built from the one
   `games.doom.wads.wadfusion` IWAD via the existing `mkDoom`/
   `programs.steam.games` mechanism -- no `conf.nix` involvement at all:
   ```nix
   WADFUSION = mkDoom {
     name = "DOOM Fusion";
     iwad = wadfusion;
   };
   WADFUSION_ROGUELIKE = mkDoom {
     name = "DOOM Fusion: Roguelike";
     iwad = wadfusion;
     wad = [ customMaps moShuffle weaponRand monsterRand corruptionCards ];
   };
   ```
   The base entry is plain WadFusion with no extra `-file`s (matches
   every other single-purpose entry already in `Doom/wad/`); the
   roguelike entry is the same IWAD with the full stack from the
   diagram above layered on via `wad`.

**Phase 3 -- map pool** (exactly the explicitly-listed set above, plus
Tech Gone Bad/Phobos Mission Control moved here from Phase 1 -- nothing
else broader):

13. `e1m8b.wad`/`e1m4b.wad` (Tech Gone Bad / Phobos Mission Control,
    Romero's Blackroom warm-up remakes, `fetchIdGames`:
    `levels/doom/Ports/d-f/e1m8b`, `.../e1m4b`) -- **belong in the
    map-shuffle pool, not WadFusion's `source_wads`**, moved from Phase 1
    above: WadFusion's own README says enabling them *replaces* E1M8 or
    E1M4 in Knee-Deep in the Dead, which is level-substitution behavior,
    not the purely-additive "one more episode" shape every other
    WadFusion input has. `build_dynamic.py`'s renumber-and-append model
    doesn't have a replace concept, so as ordinary map-pool entries they
    just become two more maps in the shuffle, which matches what they
    actually are (standalone single levels) better anyway.
01. Fetchers for: TNT: Revilution, Plutonia 2, PRCP, No End in Sight
    (all `fetchIdGames`), Doom Zero (`fetchModDB`, not idgames -- it
    isn't hosted there), Perdition's Gate (`fetchIdGames`, with an
    explicit rename from the zip's actual `Pdgate.wad` to
    `perdgate.wad`), Hell to Pay and The Lost Episodes of Doom (plain
    `fetchurl` against their archive.org zips, each with the standing
    "unlicensed-source stopgap, replace if a legit rip turns up" comment
    from the section above), TNT 2: Devilution beta 6 (`fetchurl` against
    the Dropbox link, flagged as an unusually fragile host), Japanese
    Community Project (`fetchIdGames`, `jpcp.zip`, `JPCP.wad` only --
    skip the zip's `JPCP_HUD.wad`).
01. Freedoom texture-collision filter -- when Freedoom's maps enter this
    pool, strip `TEXTURE1`/`PNAMES`/any lump that reuses an original-Doom
    texture name before merge, keeping only Freedoom's actual map lumps
    and genuinely-new textures (matches wadsmoosh-plus's own precedent,
    per the note above) -- an explicit filter step in `build_dynamic.py`,
    not an assumption.
01. **Checked, not added: "Works of the Masters" (`jp.itch.io/deluxe- master-levels`).** JP LeBreton's own (WadSmoosh's original author) 5-
    episode, 42-level "deluxe edition" of the Master Levels -- free,
    "distributed with the permission of the surviving authors," no
    retail content included, so no licensing objection. Not a clean
    map-pool add anyway, for two structural reasons: (1) its packaged
    `masters.pk3` bakes in a MAPINFO that assumes WadSmoosh's specific
    Master-Levels map-slot numbering, which conflicts with
    `build_dynamic.py`'s own generated MAPINFO/renumbering -- would need
    pulling the individual source WADs out from under the packaging
    instead, not the pk3 itself; (2) real overlap risk with WadFusion's
    own built-in "Master Levels Rejects" feature (already in Phase 1
    above) -- both draw from the same small pool of 1995-era rejected/
    extra Master Levels submissions (its own comments thread confirms
    `ACHRON22.WAD`, one of WadFusion's 15 Rejects wads, is also part of
    this compilation's "Cabal" episode), so adding both risks duplicate
    maps in the shuffle pool. Would need identifying which specific
    idgames-hosted levels in the compilation *aren't* already covered by
    WadFusion's Rejects list before it's worth adding -- not done here,
    flagged as a follow-up if wanted, not included in Phase 3's fetch
    list above.
01. **Checked DoomWiki for other id/Bethesda-staff freeware maps beyond
    what's already covered.** Went through Romero's, McGee's, and
    Willits's DoomWiki bios directly (Petersen/Hall/Green/Taylor/Cloud
    have no standalone PWAD releases listed -- their work is entirely
    inside the original retail IWADs already covered). Three real finds,
    none folded into Phase 3's fetch list above without a call-out:
    - **"One Humanity" (John Romero, 2022)** -- standalone Doom II MAP01,
      limit-removing port. **Not free**: sold for €3 at
      `romero.com/shop/p/onehumanity`, proceeds to Red Cross/UN CERF
      Ukraine relief. Same shape as Sigil/Sigil II above (small
      legitimate purchase, not a scrape) -- worth adding on the same
      basis, just needs the purchase step called out same as those.
    - **"id Map01" / `IDMAP01.WAD` (American McGee, 1994)** -- genuinely
      freeware, idgames-hosted, the only PWAD by a then-current id
      employee released outside of retail/promotional channels. **Caveat
      before adding**: DoomWiki describes it as a single-level
      *deathmatch* PWAD -- likely no monster placement/single-player
      design, which would make it a poor fit for a single-player
      roguelike shuffle pool as-is. Worth inspecting the actual WAD
      before deciding, not assuming either way from the description
      alone.
    - **"Kick Attack!" (Tim Willits, 1996)** -- a promotional tie-in for
      the (defunct) Kick soda brand, graphic/sound reskin of one level
      (demons replaced by "Alpine Spew" mascots), released in separate
      Doom and Doom II versions, idgames-hosted. Two open questions
      before adding: (1) its own graphic/sound *replacements* raise the
      same texture-collision risk flagged for Freedoom above (a reskin
      mod, not a pure add) -- would need the same collision-check
      treatment, not assumed safe; (2) it's a branded promotional
      giveaway (RC Cola/Kick), not an id/Romero personal release --
      worth confirming its actual redistribution terms rather than
      assuming idgames' long-standing hosting settles it, same standard
      applied to everything else in this doc.
    - No hit for Croteam or Serious Sam on DoomWiki at all (checked
      directly, not inferred) -- Croteam has no documented crossover
      with the Doom community or id Software; they were founded
      independently in Croatia and are now a Devolver Digital subsidiary
      (acquired 2020, not Saber Interactive -- checked before stating
      this, an earlier assumption during this research pass that Tim
      Willits's 2019 move to Saber Interactive connected to Croteam was
      wrong and dropped rather than reported). No Croteam WAD exists to
      find.

**Doom64CE feasibility for the map merge** -- turns out this repo
already has real, working infrastructure for exactly this, in
`Doom/wad/doom64.nix`: a legitimately-owned `DOOM64.WAD` (`fetchSteam`
appId 1148590, already used elsewhere in this repo, not a new source),
`Doom64CE` fetched via the existing `fetchModDB sources.wad.doom64CE`
(already in `sources.toml`), and a `wadExtractMap`/`patchFile`-based
pipeline that already extracts individual `MAPnn` lumps out of `Doom64`
and BPS-patches them against `Doom64CE`'s patcher data to reconstruct
the "Lost Levels" (MAP34-40) as their own `.pk3`. This is a stronger
starting point than any other Phase 3 candidate, but feasibility is
genuinely mixed, not a clean yes:

- **What's reusable as-is**: `doom64.nix`'s `wadExtractMap` helper
  already does the exact "pull one `MAPnn` lump out of a WAD" operation
  `build_dynamic.py` needs -- the same extraction approach could pull
  Doom64's regular maps (not just the Lost Levels) out of `Doom64` for
  feeding into the shuffle pool, reusing proven code rather than writing
  new extraction logic.
- **Bigger lift than every other Phase 3 entry**: Doom64 doesn't share
  Doom II's texture/sprite/sound resource set the way every other
  map-pool WAD does (they're plain PWADs riding on WadFusion's IWAD
  resources) -- Doom64's maps need Doom64CE's own resource pk3s
  (`doom64CEMain`/`BgmExtended`/`Brightmaps`/`Decals`/`Extra`/
  `Parallax`/`Pbr`/`SfxHq`, all already registered in
  `games.doom.wads`) loaded alongside them for textures/sprites/sounds
  to resolve at all. Feasible -- those are already ordinary loadable
  pk3s, just add them to `WADFUSION_ROGUELIKE`'s `wad` list -- but it's
  "bring an entire second resource pack," not "add one more WAD," unlike
  everything else in Phase 3's list above.
- **Real open question, not resolved here**: whether the universal
  weapon/monster randomizers and CorruptionCards (Phase 5, not yet
  sourced) actually understand Doom64-specific actors. Doom64CE's
  monsters/weapons are plausibly its own ZScript actor classes, not the
  vanilla Doom/Doom II classes those mods are likely built around --
  can't confirm compatibility without the actual randomizer/mutator mod
  code in hand (still unsourced per Phase 5), so this stays an open risk
  rather than a blocker either way.
- Lower risk than Freedoom's case on texture collisions specifically --
  Doom64CE's asset names use distinct prefixes (`D64D2`, `n64fl*`, etc)
  rather than deliberately matching original Doom names -- but "lower
  risk" isn't "verified safe," same collision-check discipline as
  everywhere else in this doc should still apply before assuming it's
  clean.

**Verdict: feasible, but scoped as a distinct stretch goal, not folded
into the main Phase 3 map-pool list above.** Given the resource-pack
requirement and the unresolved randomizer-compatibility question, this
is worth its own follow-up (possibly even a third game entry, e.g.
`WADFUSION_ROGUELIKE_D64`, rather than mixed into the main pool) once
Phase 5's gameplay mods are actually sourced and their actor-class
assumptions can be checked -- not blocking the rest of this plan.

**Phase 4 -- `build_dynamic.py` derivation:**

17. Add a pinned DoomTools release/package first. WadMerge is the MIT-licensed
    command-line utility in DoomTools, not a Python module. Expose its
    launcher on `PATH` (or wrap its JAR entrypoint) and verify the package with
    a smoke-test script. The generated script must use
    `MERGEMAPFILE outwad <new-map> <source-path> <source-map>`; `MERGEMAP`
    takes a previously declared WadMerge symbol instead of a filesystem path.
01. Package `build_dynamic.py` as its own derivation (`nativeBuildInputs = [ omgifol wadmerge ]`), taking the Phase 2 `wadfusion` output and the Phase 3
    map-WAD derivation list as inputs, producing `custom_maps.pk3`. Needs
    the script itself retargeted from the earlier wadsmoosh
    `doom_complete.pk3` naming/defaults to WadFusion's `doom_fusion.ipk3`, per the "Revised
    recommendation" pivot above.
01. Re-indexing target is WadFusion's own highest `MAPnn` slot, not
    wadsmoosh-plus's. Parse actual WAD directory/map-marker structures,
    including WAD members inside PK3/IPK3 files; filename regexes are not
    sufficient. Missing or ambiguous numeric maps fail the build rather than
    defaulting to `MAP33`.
01. Validate unique output slots and reject explicit scripted-warps unless
    their behavior is deliberately supported. MOShuffle can shuffle
    standalone maps because it changes `nextmap`/`secretmap` at runtime, but
    a map that explicitly warps elsewhere can bypass it.
01. Add deterministic resource collision handling. Renaming files alone is
    insufficient: rewrite supported map texture/flat references and relevant
    `TEXTURE1`/`PNAMES`, sound, music, MAPINFO, DECORATE, and ZScript
    references. Fail on references the tool cannot safely rewrite. Use
    fixtures for Freedoom and one resource-heavy map before expanding the
    pool.
01. Result (`custom_maps.pk3`) is one of the `wad` list entries in
    `WADFUSION_ROGUELIKE` above, not a separate registration mechanism.

**Phase 5 -- remaining stack pieces, unblocked but not yet sourced:**

20. Add the actual gameplay mods independently, not as one unverified final
    bundle: MOShuffle from CutmanMike's ZDoom release thread
    (https://forum.zdoom.org/viewtopic.php?f=43&t=72760), CorruptionCards
    v6.3b from ModDB file 293793, Vandomizer v1.3.1 from
    https://github.com/MFG38/vandomizer, and Universal Entropy v3.666b from
    https://forum.zdoom.org/viewtopic.php?t=66778. Inspect each archive,
    pin its source/hash through `sources.toml`, and register each as its own
    `games.doom.wads.*` entry. Test each layer against WadFusion and the
    minimal generated map pack before adding it to the final `wad` list.

### Feasibility check: same idea for Heretic/Hexen -- a real equivalent exists (HXDD)

Asked and checked directly, not assumed: yes, someone has built a
wadsmoosh-inspired merge tool for id Tech 1's other Raven Software
games. **`Lemon-King/HXDD`** ("A Heretic and Hexen Wad Merger," MIT
licensed, actively maintained -- pushed 2026-05-20, per its own repo
metadata) merges `heretic.wad` + `hexen.wad` + `hexdd.wad` (Hexen:
Deathkings of the Dark Citadel) into one `hxdd.ipk3`, playable via
UZDOOM/VKDOOM -- matches this repo's existing `pkgs.uzdoom` launcher
choice with no engine change needed. Its own README credits WadSmoosh
directly as the inspiration.

Real differences from the Doom-side plan, both easier and harder:

- **Simpler input story than Doom's.** Only three files needed, and
  Heretic's own expansion content ("Shadow of the Serpent Riders")
  already ships fully unified inside one `heretic.wad` -- unlike Doom's
  fragmented `base/`/`rerelease/`/Unity-branch archaeology, there's no
  equivalent version-mismatch puzzle documented for HXDD's inputs.
  **One open question this doc doesn't answer yet**: Nightdive released
  a brand-new "Heretic + Hexen" KEX-engine remaster on 2025-08-07 (same
  studio, same playbook as the Doom + Doom II relaunch that started this
  whole investigation), bundling both games, both expansions, and two
  new made-with-id-Software bonus episodes ("Heretic: Faith Renewed,"
  "Hexen: Vestiges of Grandeur") -- a close analog to Legacy of Rust.
  HXDD's README doesn't mention this release at all (likely predates it,
  or hasn't been updated for it yet) -- whether that KEX rerelease
  introduces the same classic-vs-rerelease format mismatch this doc
  spent so much effort on for Doom, and whether HXDD has since gained
  support for its two new episodes, is unchecked and would need its own
  research pass before relying on it.
- **Harder to package for this repo specifically: it's a GUI, not a CLI
  script.** Built in Java (GraalVM/Gluon for native builds, per its own
  badges), distributed as `HXDD.exe` with an interactive folder-picker
  setup wizard ("Launch HXDD.exe, select your UZDOOM folder, select your
  Heretic wad file... click Build HXDD") -- nothing in the README
  documents a headless/CLI/batch mode. wadsmoosh-plus and WadFusion are
  both plain Python scripts that run non-interactively, which is exactly
  what made the `fetchGitTree` + `pkgs.python3` derivation shape in this
  doc's plan work; HXDD as documented doesn't obviously fit that same
  shape. Would need checking whether it has an undocumented CLI flag, or
  whether it'd need building from source with some kind of scripted/
  automated GUI driver -- a real unresolved blocker for a from-source nix
  derivation, not just a detail to fill in later.
- **A genuinely interesting tie-in already built into the tool, not
  something this repo would have to invent**: HXDD's own README
  documents a "PWAD Mode" -- `hxdd.ipk3` can be loaded as a `-file` PWAD
  on top of DOOM, DOOM II, or WadSmoosh directly, bringing HXDD's classes/
  items/features into a Doom IWAD. Whether that also usefully composes
  with WadFusion (the plan's actual primary base, not wadsmoosh) is
  unconfirmed, but it's evidence the tool's author already designed for
  cross-game composition, not a wall.
- **The roguelike stack idea itself is plausibly portable**, since
  `MOShuffle`/the universal randomizers/`CorruptionCards` are GZDoom-
  family ZScript mods operating at the engine level, not hardcoded to a
  specific IWAD -- in principle nothing stops the same layering approach
  from targeting `hxdd.ipk3` as the base (`HXDD_ROGUELIKE`, same shape as
  `WADFUSION_ROGUELIKE`). Same open compatibility question already
  flagged for Doom64CE applies here too, more sharply: Heretic/Hexen's
  weapon and monster rosters are completely different from Doom's, so
  whatever the still-unsourced randomizer/mutator mods actually target
  (Phase 5 above) determines whether this is real or not -- can't
  resolve without those mods in hand.
- **Map-pool equivalent not researched here.** Heretic and Hexen both
  have their own idgames-hosted community megawad ecosystems
  (`/idgames/levels/heretic/`, `/idgames/levels/hexen/`), separate from
  Doom's -- a `build_dynamic.py`-equivalent map-shuffle pool for this
  side would need its own survey of what's out there, not done as part
  of this pass.

**Net: feasible as a parallel, not urgent, stretch goal** -- the
merge-tool half already exists and is real, but the from-source
packaging story is a genuine unknown (GUI vs CLI) unlike WadFusion's
clean Python-script shape, and the roguelike-layer half rests on the
same unanswered gameplay-mod-compatibility question already open for
Doom64CE. Worth a dedicated follow-up pass (checking for a CLI mode,
checking the Aug 2025 KEX rerelease's format story, surveying the
Heretic/Hexen idgames map-pool) if this is wanted, not folded into the
Doom-side implementation plan above.

**Moot for now, per direct instruction -- Heretic/Hexen aren't owned.**
Parked rather than pursued further; if revisited later, both the
classic Steam bundle (`store.steampowered.com/sub/439/`) and the 2025
KEX remaster ($14.99) are **purchase required**, nothing free covers
this game pair the way freeware/idgames content covers most of the
Doom-side plan. See "Purchase-required items" below.

### Purchase-required items -- not yet registered anywhere in this repo

Sweep of everything in this doc's WadFusion/roguelike-stack plan that
(a) isn't already fetched by an existing `.nix` file, and (b) costs
actual money, not just "needs finding." Doesn't include items with no
current legal purchase path at all (Hell to Pay, The Lost Episodes of
Doom -- WizardWorks-era retail, publisher defunct since 2004, nothing to
buy even if wanted; already flagged above with their own "unlicensed-
source stopgap" comment convention, which serves the same purpose as
this list for those two specifically). Doesn't include anything already
owned/registered (base Doom+Doom II, Doom 64, the Steam beta branch --
same appId 2280 depot already purchased, just a different branch).

| Item | Cost | Where | Registered anywhere yet? |
|---|---|---|---|
| Doom 3: BFG Edition (for `doom2bfg`, wadsmoosh-plus only) | Steam price | Steam appId 208200 | No |
| SIGIL with Buckethead Soundtrack (`SIGIL_V1_23_REG.wad`) | €6.66 | `romero.com/shop/p/sigilbuckethead` | No |
| SIGIL II with THORR soundtrack (`SIGIL_II_MP3_V1_0.WAD`) | €6.66 | `romero.com/shop/p/sigil-ii-thorr` | No |
| "One Humanity" (Romero, 2022 map) | €3 | `romero.com/shop/p/onehumanity` | No |
| Heretic + Hexen (classic bundle, for HXDD -- parked, not owned) | Steam sub 439 price | Steam | No |
| Heretic + Hexen (2025 KEX remaster, for HXDD -- parked, not owned) | $14.99 | Steam/GOG | No |
| Hexen II + expansions (optional HXDD bonus -- parked, not owned) | Steam/GOG price | Steam/GOG | No |

**Convention for implementation, per instruction**: when any of these
actually gets wired into a `.nix` file, leave a `# TODO:` comment at the
fetch call naming the purchase requirement, matching this repo's
existing short/terse `# TODO:` style (e.g. `topology/default.nix`'s `# TODO: Add actual IP`) -- not a full sentence, just enough to flag it on
sight. Something like:

```nix
# TODO: requires purchasing SIGIL w/ Buckethead, romero.com/shop/p/sigilbuckethead, EUR6.66
sigilBuckethead = fetchurl { ... };
```

so a `grep TODO` across the Doom module surfaces every unpurchased
dependency at a glance, rather than the purchase requirement only living
in this doc.
