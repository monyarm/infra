# Game ideas

Candidate additions to `hosts/home/monyarm/games/`, following the existing
pattern (`Doom/`, `ScummVM/`, `Steam/`) of one directory per engine/frontend
with per-source fetcher files under it.

## Shared nix helpers (proposed, not designed yet)

Two cross-cutting `lib/` helpers that keep coming up across the
mod/addon-shaped entries below -- worth a real design pass once more than
one entry actually needs them, but not designed here, just captured so the
idea isn't lost.

- **`mkModDir`** -- takes a game dir derivation plus an attrset shaped like
  `{ "path/inside/mod/dir" = drv-or-list-of-drvs; ... }`, and produces the
  merged mod-directory tree. Would cover the "many separately-fetched
  derivations need to land at specific named paths inside one folder"
  problem that shows up repeatedly above: Ikemen `chars/<name>/`,
  SuperTuxKart's `addons/{karts,tracks}/<name>/`, kart-racer addon folders.
- **`wrapGame`** -- takes a game derivation plus a list of folder paths,
  and produces a wrapper script/derivation that mounts or symlinks those
  paths to `~/.local/share/games/<drv.name>/` (or the relevant per-game
  path) before launching. Covers wiring a `mkModDir` result (or any
  nix-built folder) into whatever fixed runtime path a given engine
  actually expects -- e.g. SuperTuxKart's `~/.local/share/supertuxkart/`,
  or a Solarus quest folder -- without each entry above reinventing its
  own ad hoc wrapper.

## Ikemen GO

Open-source, cross-platform M.U.G.E.N-compatible fighting game engine
(Go rewrite of the original Winmugen/M.U.G.E.N interpreter). Characters,
stages, and screenpacks are all drop-in content -- no compilation, just
files in the right folders plus a text registration file.

- Content layout: characters live in `chars/<name>/`, each with a `.def`
  (character metadata + sprite/sound/anim file references), `.air`, `.cmd`,
  `.cns`. Registering a character for play requires an entry in
  `data/select.def` (or whatever the active motif points its select file
  at) -- just dropping files in `chars/` isn't enough, unlike ScummVM's
  `games/` directory.
- Nix-managed install shape: mirror `Doom/wad/` -- one `.nix` file per
  source (most Ikemen/MUGEN characters are hosted on GameBanana or MediaFire,
  both of which already have fetchers: `lib/fetchers/gamebanana.nix`,
  `lib/fetchers/mediafire.nix`), each producing a `chars/<name>/` derivation.
  The `select.def` entry itself has to be nix-generated too (it's just a
  line-per-character text format: `name, order, ...` flags) -- treat it like
  `Steam/shortcuts.vdf.nix` already does for a different flat config format:
  build the select.def content as a Nix string from the list of installed
  character derivations, rather than hand-maintaining a text file that can
  drift from what's actually installed.
- Roster screen: Ikemen GO's select screen is itself a moddable text format
  (`select.def`'s `[VS Screen]`/`[Options]` sections plus the referenced
  screenpack `.def`), not hardcoded -- a custom "multi-universe" grid (group
  characters by source game/franchise, maybe a second-level menu or
  color-coded portraits per universe) is achievable by hand-authoring a
  custom screenpack `.def` + `select.def` template that the nix build
  interpolates the generated roster into, rather than needing engine changes.
  `IKEMEN-LAB` and `GO-Select` (community tools) are worth reading for the
  select.def schema/edge cases, not as runtime deps.

## Sonic Robo Blast 2

The base game SRB2Kart (and Ring Racers) are built on top of: a fully
open-source 3D Sonic the Hedgehog fangame on a modified Doom Legacy (id
Tech 1 lineage) engine. Confirmed already packaged directly in nixpkgs as
`pkgs.srb2` -- no from-source build needed, unlike OpenRA. (Worth noting
for the two kart entries below too: `pkgs.ringracers` is also already in
nixpkgs, which simplifies the "not cleanly packaged" concern raised for
Ring Racers there.)

- Same WAD/addon content model, hosting (`mb.srb2.org`, GameBanana), and
  fetcher shape as SRB2Kart below -- this entry and SRB2Kart would
  realistically share the same `Doom/`-style addon-fetcher infrastructure
  once built, just pointed at platformer levels/characters instead of kart
  tracks/racers, since it's the same engine and the same addon ecosystem.

## SRB2Kart

Kart-racing mod of *Sonic Robo Blast 2* (itself a heavily modified Doom
engine fork, originally off Doom Legacy) -- id Tech 1 lineage, so it
inherits the WAD-based content model already handled for `Doom/wad/`.
Tracks and characters both ship as `.pk3`/`.wad` addon files.

- Nix-managed install shape: same as `Doom/wad/*.nix` -- addon WADs/PK3s as
  fetched derivations, symlinked/copied into an addons folder the engine
  scans on launch (`-file`/`-addfile` args or an autoload folder, depending
  on version). Most track/character addons are hosted on the SRB2 Message
  Board (`mb.srb2.org`) or GameBanana -- the latter already has a fetcher
  (`lib/fetchers/gamebanana.nix`); `mb.srb2.org` would need a small
  `fetchHtmlThenCurl`-based fetcher (same shape as `moddb.nix`/`itch.nix`)
  since it's a forum-style download page, not a direct CDN link.
- Roster/track-select screen: SRB2Kart's character/map select is driven by
  each addon's own `SOC`/Lua-defined metadata (character portraits, stats,
  map slots) -- the engine already auto-populates the select grid from
  whatever's loaded, so this is closer to "make sure the nix-generated
  addon list is consistent" than building a custom screen from scratch, but
  a custom sort/grouping (by source addon pack, like the Ikemen
  multi-universe idea) would need a small Lua mod (SRB2Kart exposes a Lua
  scripting API) hooking the select-screen draw/populate calls.

## Dr. Robotnik's Ring Racers

Kart Krew's spiritual sequel to SRB2Kart, same Doom-derived engine lineage,
now a standalone game (not a mod requiring a separate SRB2 install) with a
much larger built-in roster/track count out of the box. Addon ecosystem is
younger/thinner than SRB2Kart's -- worth checking addon availability before
investing much nix-fetcher effort here specifically.

- Same install shape as SRB2Kart: addon files (`.pk3`/`.kart`?) fetched via
  nix, dropped into an addons folder. Addons currently mostly surface on
  `mb.srb2.org`'s Ring Racers subsection -- same forum-style fetcher note as
  above applies.
- Same roster-screen note as SRB2Kart: engine-driven select grid from
  loaded addon metadata; a custom multi-universe grouping would again be a
  Lua-side hook rather than an engine patch, if Ring Racers kept SRB2Kart's
  Lua API surface (needs confirming against its actual current docs before
  committing to that assumption).

## SuperTuxKart

Fully open-source kart racer (not Doom-engine-based, own Irrlicht-derived
engine) -- included here as the "no legal-gray-area content" anchor of the
kart-racer set, and because its addon system is the most structured of the
three.

- Content layout: addons are zips that unpack straight into
  `~/.local/share/supertuxkart/addons/{karts,tracks}/<addon-name>/`, each
  addon a self-contained folder (model + textures + an XML descriptor:
  `kart.xml` or `track.xml`). `addons_installed.xml` is STK's own manifest
  of what's currently installed.
- Nix-managed install shape: same `Doom/wad/`-style per-source fetcher
  files, but simpler than the WAD case since STK addon zips are already
  self-contained, correctly-shaped folders once extracted -- no
  registration file to hand-generate (unlike Ikemen's select.def), *except*
  `addons_installed.xml` needs the nix build to append/generate matching
  entries or STK's own addon manager won't recognize them as installed.
  Most addons are hosted on the official `stk-addons` server
  (`online.supertuxkart.net`) with a real API (`fetchHtmlThenCurl` should
  cover it) or mirrored on GameBanana.
- Track/racer notes: STK doesn't have a "roster screen" in the fighting-game
  sense, but the same idea applies to the kart-select and track-select
  screens -- both are driven by installed-addon metadata already, so a
  nix-managed install list keeps them in sync automatically; a
  multi-universe grouping here would mean a custom "track group" (STK
  supports grouping tracks into named groups via `track.xml`'s `<group>`
  field already) per franchise, which is native functionality, not a mod.

## OpenMW

Open-source Morrowind engine reimplementation -- ships zero game content,
requires a legally-owned copy of the original data (CD/GOG/Steam). GOG's
version is already exactly what `lib/fetchers/gog.nix`'s `fetchGOG` handles
generically (InnoSetup `.exe` -> `innoextract --gog`, not ScummVM-specific
despite living alongside the ScummVM callers) -- Morrowind's base data dir
comes straight out of that fetcher with no new fetcher code needed.

- **Multi-data-dir is what makes this a good nix fit, specifically**:
  `openmw.cfg` takes any number of `data="..."` lines, each pointing at an
  independent folder, layered by declaration order (later = higher
  priority, per-resource -- a mod's texture overrides the base game's same
  filename without needing the two merged into one directory first). That
  means each mod can stay exactly what a nix fetcher naturally produces --
  an immutable, content-addressed store path -- and get listed as its own
  `data=` line directly, with **no symlink-farm/merge step** the way an
  engine that expects one flattened data folder would need. Base game +
  every installed mod is just an ordered list of store paths.
- Nix-managed install shape: one `.nix` file per mod source, each a plain
  derivation (extracted mod archive, nothing GOG-specific). Nexus Mods is
  the dominant host for Morrowind mods -- already has a fetcher
  (`lib/fetchers/nexus.nix`); ModDB shows up for some older/classic mods
  too (`lib/fetchers/moddb.nix` already covers that shape). The `openmw.cfg`
  itself becomes nix-generated: build the ordered `data=`/`content=` lines
  from the list of installed mod derivations plus their declared load-order
  weight, same "generate the flat config from a derivation list" idea
  `Steam/shortcuts.vdf.nix` already uses for a differently-shaped format.
- `content=` lines (plugin `.esp`/`.omwaddon` files, order-sensitive
  separately from `data=` dirs) need their own explicit ordering input --
  can't be inferred purely from `data=` order, so the generated config
  needs a real load-order list as an input, not just "the mod derivation
  list in some order."

## Daggerfall Unity

Open-source Unity reimplementation of The Elder Scrolls II: Daggerfall --
same "engine reimplementation needing original data" shape as OpenMW, but
a cleaner legal case: Bethesda made Daggerfall's original game files
freeware outright back in 2009 (no purchase needed), available directly
from Bethesda.net, Steam (free), and GOG. Already packaged in nixpkgs as
both `daggerfall-unity` and `daggerfall-unity-unfree` -- worth checking
what actually distinguishes the two (likely whether the freeware original
data is bundled/auto-fetched vs. left to the user) before picking one.

- Since the data is freeware rather than a paid GOG purchase, this could
  skip the `fetchGOG`/`GOG_AUTH`-authenticated-download path entirely --
  either a direct `fetchurl` against Bethesda.net's or archive.org's
  freeware release, or (if going through GOG specifically for update
  convenience) `fetchGOG` still works unmodified for a free-to-claim GOG
  library item, same mechanics as a paid one.
- Real mod ecosystem via Nexus Mods, same as OpenMW -- `lib/fetchers/nexus.nix`
  already covers that, so the same "each mod is a nix-fetched derivation"
  approach applies here too, though Daggerfall Unity doesn't have OpenMW's
  multi-`data=`-directory mechanism specifically -- worth checking its own
  actual mod-loading model (StreamingAssets/mod bundles) before assuming
  the same no-merge-step story carries over.

## Tyrian / OpenTyrian

Freeware DOS scrolling shooter (Eclipse Software/Epic MegaGames, 1995) --
made freeware outright by its creator, Jason Emery, in 2004. OpenTyrian
(started 2007) is an open-source engine port, and unlike every other
engine-reimplementation entry in this file, it bundles the freeware
Tyrian 2.1 data files directly in its own release: there's no separate
data-fetch/legal-ownership step at all, the OpenTyrian download already is
the complete, legally redistributable package.

- Already packaged in nixpkgs as `pkgs.opentyrian` -- about as simple as
  this category gets, likely just a `home.packages` add with no custom
  derivation work needed at all, unlike every other entry here that needs
  its own fetcher.

## DevilutionX

Diablo 1 (+ Hellfire expansion) engine reimplementation, decompiled from
the original 1.09b binary -- mature and actively maintained, with
widescreen, gamepad support, QoL fixes, modding, and multiplayer. Already
packaged in nixpkgs as `pkgs.devilutionx`, so this is a `home.packages`
add plus a data fetcher, not a from-source build.

- Needs `DIABDAT.MPQ` from a Diablo install -- GOG sells Diablo, so this
  is a direct `fetchGOG` case, same mechanics as OpenMW/Daggerfall Unity
  above: `innoextract --gog` the installer, pull `DIABDAT.MPQ` out of the
  result.
- Picked over Freeablo (the clean-room alternative): Freeablo is
  noticeably less complete ("work in progress" by its own description),
  isn't packaged in nixpkgs, and its original upstream repo is now
  archived/unmaintained. DevilutionX wins on maturity and packaging effort
  by a wide margin.

## OpenRA

Open-source engine reimplementation covering the earliest Westwood
Command & Conquer titles (Tiberian Dawn, Red Alert, plus community mods for
Dune 2000/Tiberian Sun). Different legal shape from OpenMW: EA released the
original Tiberian Dawn and Red Alert as freeware outright under the C&C
Modding Guidelines, not "you must already own a copy" -- and OpenRA's own
in-game content manager already knows how to fetch those freeware releases
directly (or detect a real install/disc if present).

- Not cleanly packaged in nixpkgs as a top-level attribute (only scattered
  `openraPackages_2019.mods.*` derivations for community mods) -- building
  it would likely mean packaging upstream's release tarball or building
  from source, not just referencing an existing `pkgs.openra`.
- Nix-managed install shape: worth checking whether the content-manager's
  freeware-download step can just run as part of the derivation's build
  (network access at build time is the usual nix wrinkle -- would need
  either a fixed-output derivation like the other fetchers here, or baking
  a known-good freeware release URL into a plain `fetchurl`) rather than
  needing a bespoke scraping fetcher the way GameBanana/ModDB-hosted
  content does.

## OpenTTD

Open-source Transport Tycoon Deluxe engine reimplementation -- the
contrast case among these three. OpenGFX/OpenSFX/OpenMSX are themselves
fully open-licensed replacement graphics/sound/music base sets (not a
legal workaround, the actual recommended way to run OpenTTD), so the base
game needs **no** fetched proprietary data at all: `pkgs.openttd` (already
in nixpkgs) plus the open base sets, done.

- Only becomes an interesting nix-fetcher target the same way the kart
  racers are: OpenTTD has its own in-game "online content" service for
  NewGRFs (custom vehicle/industry/town-name sets), AI scripts, and game
  scripts -- a nix-managed content list here would mean a fetcher for that
  content service specifically, not for the base game itself. Worth
  scoping only if the NewGRF-modding angle is actually wanted; the base
  game is a zero-effort `home.packages` add on its own.

## The Dark Mod

Free, standalone stealth game (Thief-inspired) on id Tech 4 -- originally
a Doom 3 mod, spun off in 2013 into a fully standalone free game using the
open-sourced id Tech 4 engine with entirely original assets, so unlike
OpenMW/Daggerfall Unity/Arx Libertatis it needs **no** externally-owned
game data at all. Not currently in nixpkgs (`thedarkmod`/`darkmod` both
came up empty) -- would mean packaging from their own installer/source.

- Distribution is via their own `tdm_installer` (also mirrored on Steam,
  free) rather than a generic archive download -- worth checking whether
  the installer fetches content in a fixed-output-derivation-friendly way
  (stable URLs/checksums) before assuming a straightforward `fetchurl`.
- **Fan missions are the real content-ecosystem angle here**, same spirit
  as Ikemen chars/kart tracks: 190+ community-made missions (some
  multi-mission campaigns), normally installed through an in-game "New
  Mission" downloader hitting TDM's own mirror network. A nix-managed
  mission list would mean a fetcher for that specific hosting (need to
  identify the actual mirror/API shape) producing per-mission folders,
  same "many small fetched derivations, one per piece of content" pattern
  as everything else content-ecosystem-shaped in this file.

## The Legend of Zelda: Mystery of Solarus DX

Runs on Solarus, an open-source 2D action-RPG engine (Zelda-style) that was
originally built specifically for this game. Freeware, open source, own
assets -- no proprietary data-fetch story like the reimplementation-style
entries above.

- Content model: Solarus games ship as self-contained "quests" -- a data
  folder plus a `quest.dat`/project file, loaded by the same Solarus player
  binary. Several other games exist on the same engine (Return of the
  Hylian, Zelda: Solarus of the Wild, non-Zelda quests too) -- same shape
  as Ikemen's chars/select.def idea, but at the whole-game level rather
  than per-character: each quest is one fetched/extracted derivation, and
  a launcher picks which quest folder to hand to the Solarus player. Not
  really "roster" content in the kart-racer/Ikemen sense (no mixing content
  across quests at runtime), so no custom-select-screen angle here -- just
  a nix-managed list of installable quests.
- Nix-managed install shape: quest downloads are mostly hosted directly on
  `solarus-games.org` or the quest's own project page -- would need a
  small `fetchHtmlThenCurl`-based fetcher (same shape as `moddb.nix`) for
  the former, direct `fetchurl` likely fine for anything with a stable
  release URL.

## RPG Maker native runtimes (mkxp-z / EasyRPG)

Not a game itself -- shared runtime infrastructure any RPG Maker-based
entry in this file (Pokémon Infinite Fusion below, and any future one)
should sit on top of, rather than each game getting its own bespoke
Wine/Bottles/Lutris setup. RPG Maker's engine generations split cleanly
into two unrelated tech stacks, each with one open-source native-Linux
player project:

- **mkxp-z** -- covers RPG Maker XP / VX / VX Ace (the RGSS/Ruby-scripted
  generation). Purpose-built to handle Pokémon Essentials-based games'
  heavy reliance on Windows APIs specifically, confirmed working for
  Infinite Fusion on Linux/Steam Deck. This is the one Infinite Fusion
  needs.
- **EasyRPG Player** -- covers the older RPG Maker 2000 / 2003 generation
  (LCF-format, no Ruby scripting). This repo's own
  `RPGMaker/default.nix` already references it (the `EasyRPG Editor.conf`
  `rtp_path` stanza) but only as editor-tool config today, not wired up as
  an actual player/runtime for any installed game yet.
- Nix-managed shape: package both once as shared derivations/packages
  (nixpkgs may already have one or both -- worth checking before building
  from source), then each RPG-Maker-based game entry just becomes "which
  runtime + which game data," the same way `Doom/default.nix` is one
  source-port package shared across every WAD in `Doom/wad/`, rather than
  each WAD carrying its own engine copy.

## Ren'Py shared runtime

Same shared-engine idea as the RPG Maker runtimes above, applied to the
`RenPy/` directory that already exists in this repo (currently just
`default.nix`, symlinking a shared `.renpy` persistent-save-data folder --
no actual game-install layer yet, just the save-data plumbing).

- Ren'Py's own distributed-game layout already separates cleanly: a
  downloaded build bundles `renpy/` + `lib/` (the interpreter, per-game
  copies of the same engine binaries and bundled Python) alongside `game/`
  (that title's actual script/asset content) -- only `game/` is
  title-specific. The engine copy any given download ships is pure cruft
  once a shared SDK is in place, same shape as `gog.nix`'s `gogCruft` list
  stripping the GOG/Galaxy chrome down to just the game data.
- Running a game against a SDK/install that isn't the one it shipped with
  is an officially-supported shape, not a hack: point the shared `renpy`
  binary at any directory containing a `game/` subfolder (either directly
  on the command line, or registered via the launcher's `projects.txt`) and
  it runs. Ren'Py maintains broad backward compatibility across versions,
  so one current shared SDK covering older titles too is realistic --
  though very old (Ren'Py 6-era) games are the one place this could
  actually break and would need checking per-title, not assumed safe.
- nixpkgs already has both `renpy` and `renpyMinimal` -- worth checking
  which one actually corresponds to "just the runtime, no bundled
  editor/launcher UI" before picking one to wire up as the shared engine
  package this directory's games run against.
- Nix-managed install shape: same `Doom/wad/`-style per-source fetcher
  files, each one fetching a title's distributed build and keeping only
  its `game/` folder (existing `removeFiles`-style cruft-stripping, same
  tool `gog.nix` already uses). Katawa Shoujo (already present as a real
  save-data example in `.renpy/katawashoujo_actual_1.3/`) would be the
  natural first title to wire up this way, since its persistent-data
  plumbing already exists and only the fetcher/game-folder half is
  missing. Common hosting: itch.io (`lib/fetchers/itch.nix` already
  covers it) is the dominant source for freeware/indie Ren'Py titles.

## Katawa Shoujo

The concrete first title for the Ren'Py shared runtime above -- already
half-present in this repo: `.renpy/katawashoujo_actual_1.3/persistent`
exists as real save-data plumbing, but nothing actually fetches/installs
the game itself yet. Freeware visual novel (Four Leaf Studios), assets
released under Creative Commons, no legal complexity -- hosted on the
project's own site (katawa-shoujo.com), itch.io, and Steam (free).

- Nix-managed shape: exactly the `RenPy/`-shared-runtime pattern above --
  fetch the distributed build, strip it down to just `game/` (drop the
  bundled `renpy/`/`lib/` engine copy), run it against the shared `renpy`
  package. itch.io is likely the easiest source given
  `lib/fetchers/itch.nix` already exists; the project's own site would
  need a plain `fetchurl` if it has a stable direct download link.

## Mari0

Open-source Super Mario Bros. x Portal crossover built on LÖVE (nixpkgs
has `love_11`, matching the version range Mari0-CE -- the actively
maintained community fork -- targets). Own engine, own assets, no
proprietary-data story.

- Content ecosystem: ships with a level editor, and GameBanana is the
  primary hub for community mappacks/mods extending the base game with new
  levels, mechanics, and graphic sets -- same shape as every other
  GameBanana-hosted content case here (`lib/fetchers/gamebanana.nix`
  already covers it). Mari0-CE itself (the fork worth actually packaging,
  given upstream Stabyourself.net development has stopped) is a GitHub
  release, straightforward `fetchurl`/`fetchFromGitHub`.
- Not really "roster" content in the Ikemen/kart-racer sense -- mappacks
  are standalone level sets you pick one of, not composable pieces mixed
  into one roster -- so this is closer to the Solarus quest-list shape
  (nix-managed list of installable content, no custom-select-screen work)
  than to Ikemen's per-character merge.

## Pokémon Infinite Fusion

Fan-made Pokémon game (fuses two Pokémon into one, procedurally-composited
sprites), built as an RPG Maker XP project on top of the Pokémon Essentials
framework -- distributed as a full game download (game logic/maps/scripts
plus a large fusion-sprite asset pack), not from source. Runs on **mkxp-z**
(see above), not Wine.

- Content layout: the game logic itself lives in a GitHub repo
  (`infinitefusion/infinitefusion-e18`), but explicitly isn't a complete
  project on its own -- it's meant to be merged into an existing RPG Maker
  XP project tree (base RTP + the large fusion-sprite graphics pack), which
  the community currently distributes as a full pre-merged zip via the
  project's Discord rather than anywhere with a stable direct-download URL.
  That Discord-only distribution is the real blocker to a clean nix fetcher
  here -- worth checking whether the GitHub repo's own releases (if any)
  or a mirror have a fetchable stable artifact before assuming a
  `fetchHtmlThenCurl`/manual-URL fetcher is even feasible the way it is for
  the GameBanana/itch/ModDB-hosted content elsewhere in this file.

## PokéRogue

Browser-based Pokémon roguelite fangame (`pagefaultgames/pokerogue`,
AGPL-3.0, TypeScript/Phaser), with a separate server backend
(`pagefaultgames/rogueserver`) for save data, daily runs, etc. -- both
fully open source and explicitly support self-hosting (server repo
documents both Docker and native install paths).

- Architecturally different from everything else in this file: it's a
  self-hosted **web app + API server**, not a client-side game install
  under `hosts/home/monyarm/games/`. This repo doesn't have an established
  self-hosted-service pattern yet (`hosts/nixos/` currently has just the
  one `gaming-laptop` host, no `services.*`/container-based app examples
  to follow) -- adding this would be establishing that pattern for the
  first time here, not slotting into an existing one, worth treating as a
  bigger scope decision than the other entries in this file.
- If pursued: `rogueserver`'s Docker path is the more nix-idiomatic fit
  (`virtualisation.oci-containers` or a from-source `buildGoModule`-style
  package + a `systemd` service unit), with the frontend served as a static
  build (`pokerogue`'s own build output) behind whatever's already
  terminating TLS/reverse-proxying on this host, if anything is.

## Legally redistributable game ROMs

Need a source survey before adding a `hosts/home/monyarm/games/ROMs/`
(or similar) directory -- distinct from `Doom/wad/idgames.nix`'s model
since ROM legality is per-title, not per-source the way idgames.net (all
Doom mods, no legality question) is.

Leads worth checking against actual current terms before fetching anything:

- **PDRoms** (`pdroms.de`) -- catalogs homebrew, donationware, open-source,
  and public-domain releases specifically cleared for free redistribution,
  across NES/SNES/GB/GBA/Genesis/Atari/Commodore and more. Best single
  starting point; per-title license still needs checking (a few skew
  "freeware, no redistribution" rather than PD).
- **Homebrew game jams/compos** (itch.io homebrew tags, `Mode7Games`-style
  compilations, NESdev/SGDK community jam entries) -- already have an itch
  fetcher (`lib/fetchers/itch.nix`) that would cover these directly, same
  pattern as ScummVM's itch-sourced games.
- **Official public-domain re-releases** -- e.g. id Software's own shareware
  episodes (already covered via `freedoom.nix`/`idgames.nix` for the Doom
  case), and similar cases where the original rightsholder explicitly
  released ROMs/binaries free (worth a per-console survey rather than
  assuming a blanket source exists).
- Explicitly **not** a lead: general "ROM site" aggregators (the
  itechguides/techbloat/positioniseverything-style "best ROM sites" lists) --
  these mix legitimately-free titles with straightforwardly infringing
  commercial ROMs and don't reliably distinguish the two per-title, so they're
  not a safe source to build a fetcher against without manually verifying
  each specific title's license first.
