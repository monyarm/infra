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
- **Owned copy is a physical CD, not GOG** -- the `fetchGOG` path above
  doesn't apply to this specific copy. `DIABDAT.MPQ` needs pulling off the
  disc by hand first; the result then becomes a local, hash-pinned source
  (plain store path, not a network fetcher) feeding the same DevilutionX
  data wiring `fetchGOG` would have. Same disc-sourcing caveat applies to
  every other disc-owned title in this file below.

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

## Kathy Rain

Point-and-click adventure built on Adventure Game Studio (AGS) -- no
separate reimplementation project needed, ScummVM's built-in AGS engine
already plays it directly (confirmed on ScummVM's own compatibility pages;
minor issues that don't affect playthrough). Same install shape as every
other ScummVM entry in this repo already: the Steam release's game
directory (containing the `.ags` data file) becomes a `games.scummvm.games`
entry via `fetchSteam`, same pattern as
`hosts/home/monyarm/games/ScummVM/games/steam.nix`. No fetcher gap, no
modding ecosystem worth tracking -- this is close to the cheapest entry in
this whole file.

## KeeperFX

DK1-specific engine reimplementation for Dungeon Keeper (Gold) -- actively
maintained (v1.4.0, mid-2026, ~200K downloads), not a binary patch but a
full from-scratch rewrite that still only needs the original GOG data as
proof of ownership. Not in nixpkgs yet, so this would be a from-source
package (CMake, moderate complexity) added under `packages/`, unlike the
already-packaged engines elsewhere in this file.

- Data: base game assets straight out of the GOG install --
  `lib/fetchers/gog.nix`'s `fetchGOG` on the `dungeon_keeper` product slug,
  same mechanics as OpenMW/Daggerfall Unity/DevilutionX above.
- KeeperFX effectively *is* the mod layer (built-in level editor, active
  balance/content development) -- no separate community-mod fetcher list
  needed on top of it, unlike the Ikemen/STK/TDM content-ecosystem entries.

## OpenRCT2

Already-packaged (`pkgs.openrct2` in nixpkgs, mature and cross-distro),
auto-detecting RCT1 data once pointed at an RCT2 install -- about as
low-effort as the OpenTyrian entry above. `pkgs.openrct2`'s own package
exposes `rct1Path`/`rct2Path` override args for baking a known data
location in at build time, rather than needing the in-game
first-launch file picker.

- Data: `lib/fetchers/gog.nix`'s `fetchGOG` on `rollercoaster_tycoon_deluxe`
  feeds `rct2Path` directly, same `fetchGOG`-then-point-a-package-at-it shape
  as DevilutionX's `DIABDAT.MPQ`.
- Content ecosystem: large scenario/track-design/object addon community --
  same "many small fetched pieces, one nix-managed list" shape as
  everything else content-ecosystem-shaped in this file, though (like
  OpenTTD's NewGRF angle) only worth scoping if the addon side is actually
  wanted; the base game is a zero-effort win on its own.

## Half-Life (Xash3D-FWGS)

GoldSrc engine reimplementation covering Half-Life, Half-Life: Opposing
Force, and Half-Life: Blue Shift -- actively maintained fork (the upstream
FWGS org, old repo archived, this one continues). Needs building from
source (Waf build system, SDL2/freetype/vorbis deps); an open nixpkgs PR
exists but isn't merged, so this would be a `packages/` addition here too,
same shape as KeeperFX above.

- Data: just the `valve/` asset directory out of each title's Steam depot
  (no binaries) -- `fetchSteam` per appid (70 / 50 / 130), same
  depot-extraction shape as `Doom/wad/doom64.nix`'s `fetchSteam` call, piped
  through `getFile`/`wadFilter`-style filtering to keep only the asset tree.
- No significant centralized mod ecosystem worth a nix-fetcher list --
  community fixes are scattered, not worth the infrastructure the
  GameBanana/ModDB-hosted entries elsewhere in this file get.

## Portal 2

Puzzle-platformer (Valve, Source engine) -- native Linux Steam build, unlike
the Xash3D-FWGS reimplementation the Half-Life entry above needs; this is a
straight `fetchSteam` binary extraction. Steam-only, no GOG release.

- Data: `fetchSteam` [appid 620], native Linux depot, standard extraction
  shape.
- Mod support: real ecosystem -- official in-game Puzzle Maker for
  user-built test chambers, Steam Workshop integration for sharing/playing
  co-op community chambers, GameBanana presence, 25 mods on NexusMods
  (modest -- most activity is Workshop-side, not Nexus). Worth a
  Workshop-content fetcher list if pursued further, same spirit as this
  file's other Workshop-backed entries.

## Half-Life 2 (+ Episode One, Episode Two)

Source-engine FPS (Valve) -- native Linux Steam build, `fetchSteam` binary
extraction like Portal 2 above. Steam-only, no GOG despite the base game
being DRM-free on Steam itself.

- As of the Nov 2024 20th-anniversary update, Episode One, Episode Two, and
  Lost Coast are bundled into the base HL2 app (delisted as separate store
  listings, launched from the HL2 main menu) -- one `fetchSteam` [appid 220]
  call covers all three instead of three separate appids (380/420 still
  exist as legacy "Tools" entries but aren't the current path).
- Mod support: largest ecosystem of the Source titles here -- built-in
  Steam Workshop (added same anniversary update), 95 mods on NexusMods
  (HD texture packs, gameplay overhauls), extensive GameBanana/ModDB
  presence, notable standalone total conversions historically spun off
  the base (MINERVA, etc.). Worth a Workshop/GameBanana/NexusMods fetcher
  list if pursued.

## Jedi Knight: Jedi Academy / Jedi Outcast (OpenJK)

Actively maintained reimplementation covering both STAR WARS Jedi Knight:
Jedi Academy and Jedi Knight II: Jedi Outcast -- but not symmetrically:
Academy is fully supported, Outcast singleplayer is still experimental/
disabled by default (Outcast multiplayer instead routes through the
separate JK2MV project, not OpenJK). Already packaged in nixpkgs.

- Data: each title's `GameData/` directory out of its Steam depot --
  `fetchSteam` per appid (6020 Academy, 6030 Outcast), same shape as the
  Half-Life entry above.
- Real mod ecosystem: JKHub (jkhub.org) hosts 3000+ mods with an active
  forum -- would need a small `fetchHtmlThenCurl`-based fetcher (same shape
  as `moddb.nix`) since it's forum/site-hosted content, not a CDN with a
  stable API.

## DOOM 3 (dhewm3 vs. RBDOOM-3-BFG)

Not a "which is better" choice -- the two owned DOOM 3 releases ship
genuinely incompatible data formats, so each release needs its own engine:

- **dhewm3** (nixpkgs-packaged, actively maintained, v1.5.4) targets the
  original 2004 release's loose `.pk4` archives (Quake 3-style format) --
  use this for DOOM 3 [appid 9050] and Resurrection of Evil [appid 9070].
- **RBDOOM-3-BFG** (nixpkgs-packaged, actively developed with nightly
  builds and 40+ contributors) targets the 2012 BFG Edition's repackaged
  `.resources` binary containers with remastered textures/shaders -- use
  this for DOOM 3: BFG Edition [appid 208200]. Original-release data doesn't
  fit RBDOOM-3-BFG's expected container structure (some export/conversion
  tooling exists but that's a workaround, not the natural path); BFG
  Edition's data likewise doesn't work in dhewm3.
- Data: `fetchSteam` per appid, straightforward since both engines are
  already nixpkgs-packaged -- this is a `home.packages` + data-fetcher pair
  for each, not a from-source build like most of the entries above.
- Mod ecosystem: both have real ModDB communities (dhewm3: hidef2k, sikkmod
  and similar overhaul mods; RBDOOM-3-BFG: derivative forks like DOOM: BFA
  adding Ultimate DOOM/DOOM 2 compatibility) -- `lib/fetchers/moddb.nix`
  already covers the hosting, so this is a "yes, worth a fetcher list if
  wanted" case unlike the plain OpenXcom/Half-Life entries above.

## Fallout / Fallout 2 (fo1-ce / fo2-ce / fo1in2)

Both community editions are mature, actively maintained decompilation-based
ports -- fo1-ce (alexbatalov/fallout1-ce) and fo2-ce, whose canonical repo
has since moved to the `fallout2-ce` org (not alexbatalov's personal
account anymore -- worth pointing at the current org, not an outdated URL).
Both need the unpacked original game data (`critter.lst`, `master.dat`,
etc.) straight out of each title's Steam depot.

- Data: `fetchSteam` on appid 38400 (Fallout) / 38410 (Fallout 2), same
  depot-extraction shape used throughout this file. Neither engine needs
  anything beyond that -- no GOG-specific wrinkle here since both are owned
  on Steam.
- No major third-party mod CDN to track -- native `.dat` mod support
  exists, but community mods are small and scattered across NMA forums/
  GitHub, not worth a dedicated fetcher list.
- **fo1in2** (rotators/Fo1in2, aka "Fallout et Tu") is a different thing
  entirely from the two CE ports above: a total-conversion mod that runs
  Fallout 1's full campaign inside the Fallout 2 engine (enhanced combat,
  motorcycle travel, optional F2-style content, toggleable via ini). It
  needs *both* games' data (Fallout 1's `MASTER.DAT` gets extracted via a
  bundled tool) and layers on top of either vanilla Fallout 2 or fo2-ce --
  worth treating as an optional third entry alongside the two CE installs,
  not a replacement for either.

## Infinity Engine Enhanced Editions (GemRB caveat -- no clean path currently)

Worth flagging clearly rather than writing this up as a settled win: GemRB
is a mature, actively maintained Infinity Engine reimplementation, but per
GemRB's own 0.9.5 release notes it explicitly does **not** support the
Beamdog Enhanced Edition data format that this repo's owned titles actually
are (Baldur's Gate: EE, Baldur's Gate II: EE, Icewind Dale: EE, Planescape:
Torment: EE) -- "due to low interest, GemRB does not support the EE
versions of the games." BG2:EE has experimental/unstable support
(Shadows of Amn campaign playable); the other three EE titles aren't
supported at all.

- This means there's currently no clean engine-reimplementation path for
  the specific Enhanced Edition copies owned here -- GemRB only plays the
  classic, pre-Beamdog releases, which would mean separately acquiring the
  original (non-EE) data rather than pointing GemRB at the owned Steam
  copies. Not worth pursuing as-is; revisit if GemRB's EE support matures,
  or if the classic releases become available through some other owned
  channel.
- Mod ecosystem note for if the classic-data path is ever pursued: the
  Infinity Engine mod scene (Spellhold Studios, Gibberlings3) is real and
  active, but targets the original engine or EE format specifically, not
  GemRB's reimplementation -- compatibility would be mod-by-mod, not a
  blanket fetcher-list win the way GameBanana/ModDB content usually is here.

## Build engine trio (eDuke32 / Raze / VoidSW)

Not a single three-way engine choice -- the two owned Build-engine titles
each need their own answer, and neither is a clean win:

- **Duke Nukem 3D: 20th Anniversary World Tour** [Steam appid 434050] --
  the Steam release itself is Windows-only (no native Linux binary), and
  Proton has reported failures on it (process kills, DLL issues). The
  open-source path is eDuke32 pointed at the title's extracted data files
  plus community patches for the World Tour-specific episode content --
  workable per community reports, but manual/patched, not "just point
  fetchSteam at it and go." The earlier candidates-file note that this
  "already ships on eduke32 upstream, nothing to port" does **not** hold up
  under checking -- treat this as a real, moderately fiddly port, not a
  freebie.
- **Shadow Warrior Classic Complete** \[GOG slug: `shadow_warrior_complete`\]
  (base game + Wanton Destruction + Twin Dragon expansions) -- pick
  **VoidSW** for a faithful software-rendered classic experience (actively
  maintained by the eDuke32 team, more reliable Twin Dragon expansion
  detection); **Raze** is the alternative if external sound/texture mod
  support matters more than expansion-detection reliability (some reported
  GOG folder-structure quirks recognizing Twin Dragon specifically). Raze
  is the multi-engine Build port (also covers Duke3D, Blood, etc. in one
  codebase) and has more GitHub packaging interest, but VoidSW is the
  simpler, more faithful pick for this specific title.
- Data: `fetchSteam` (appid 434050) / `fetchGOG` (`shadow_warrior_complete`)
  respectively, feeding whichever engine's expected data-directory layout.
  None of eDuke32/Raze/VoidSW are confirmed current in nixpkgs -- from-source
  builds, same category as KeeperFX/Xash3D-FWGS/TFE above.
- Mod ecosystem: large community level/mod presence on Duke4.net for both
  titles -- Raze's external sound/sprite-pack support makes it the more
  mod-friendly target if that ecosystem is ever wired up as a fetcher list.

## Serious Sam Classic (SeriousSamClassic-VK)

Single actively maintained Vulkan-backed port (tx00100xt/SeriousSamClassic-VK)
covering all three owned Serious Engine 1 titles -- The First Encounter,
The Second Encounter, and the Classics: Revolution community-remaster
bundle, since Revolution targets the same underlying engine. No nixpkgs
package currently (a PPA exists for Debian-family distros, not relevant
here) -- from-source build, GPLv2, same category as the other from-source
engines in this file.

- Data: original `.gro` game archives copied from each title's Steam
  depot -- `fetchSteam` per appid (41050 / 41060 / 227780).
- No dedicated nix-fetcher-worthy mod ecosystem beyond what ships with the
  binary archive bundles the project itself distributes.

## Neverwinter Nights (xoreos -- not currently playable)

Worth flagging the same way as the GemRB entry above rather than writing it
up as viable: xoreos remains pre-alpha per the project's own current status
page -- foundational resource-loading/rendering work is done, areas
partially render in a "spectator mode," but there's no combat, scripting,
dialogue, or quest system implemented yet. It also only recognizes the
original Neverwinter Nights Diamond Edition data, not the owned NWN:
Enhanced Edition [Steam appid 704450] release at all.

- Not worth pursuing as an install target today for either owned NWN
  release -- revisit only if xoreos reaches actual playable status, which
  it has not as of this research pass.

## Space Quest Collection

Steam's "Collection" bundle [appid 10110] is not a ScummVM case despite
Sierra's SCI-engine games normally running there -- it ships as six
separate pre-configured DOSBox 0.63 instances, one per game, each mounting
its own folder (`sq[1-6]/DOSBOX/`) and launching with game-specific
parameters. The bundled DOSBox is old enough to have known compatibility
issues on modern systems, and repackaging six fragile per-game DOSBox
setups isn't a clean nix-fetcher target.

- Better split: Space Quest I-V actually run fine on ScummVM's own SCI
  engine (same shape as this repo's other ScummVM entries, no DOSBox
  needed at all) -- only Space Quest 6 genuinely requires DOSBox, since SCI
  support doesn't extend that far. `lib/fetchers/dosbox.nix` covers just
  that one title; the rest go through the existing ScummVM `games/` pattern.
- Data: `fetchSteam` on appid 10110, then split extraction -- SQ1-5 game
  folders feed ScummVM entries, SQ6's folder feeds the DOSBox path.

## Fallout Tactics (FreeFT -- WIP, not playable end-to-end)

FreeFT (nadult/FreeFT) is unmaintained and genuinely incomplete, not just
"early but usable" -- missing lighting, RPG dialogue/scripting, and quest
systems entirely; movement and combat work as a tech demo, but there's no
complete game loop. Requires converting the original Fallout Tactics data
[Steam appid 38420] into FreeFT's own format via a bundled conversion tool
before the engine can use it.

- Not recommended for actual play today -- worth revisiting only if the
  project sees renewed development, otherwise this is a "known dead end,
  don't invest fetcher effort" entry, same spirit as the OpenRW/Alive
  Reversing WIP caveats already noted in the candidates-file source pass.

## Unity Player-binary swap builder (unify)

Extends the existing "Unity -- swap matching-version Linux Player binaries"
note above: [unify](https://github.com/0xf4b1/unify) is the actively
maintained tool that actually automates that swap -- detects a Windows/
macOS Unity title's exact engine version, pulls the matching official Linux
Player build from Unity's own distribution servers, and drops it in to
produce a native Linux launch, without touching game assets or scripts. Its
real constraint is the same one already noted: only works if the original
build used a portable renderer (OpenGL/Vulkan, not pure DX) and doesn't
lean on Windows-only native plugins.

- Nix shape: package `unify` itself once as a plain tool (build from source,
  Go or similar toolchain per its repo) under `packages/`, then any
  Unity-title entry in this file that turns out to be a good match can
  invoke it as a build step rather than each one reinventing the
  version-detection/binary-fetch logic -- same "shared tool, per-title
  application" relationship as the mkxp-z/EasyRPG runtimes above.

## The Dig / Full Throttle / Sam & Max Hit the Road (ScummVM, disc rip)

Three more LucasArts SCUMM-engine adventures, same ScummVM install shape as
Kathy Rain above -- but unlike Kathy Rain (Steam, `fetchSteam`) and every
other digitally-owned ScummVM-shaped entry in this repo, **these are owned
as physical CDs**, not Steam/GOG. No `fetchGOG`/`fetchSteam` path exists for
them: the game directory has to come off the disc by hand first, then be
added as a local, hash-pinned source (plain store path) feeding the same
`games.scummvm.games` entry shape everything else here uses -- the ScummVM
side of the work is identical to Kathy Rain, only the data-acquisition step
differs.

## StarCraft + Brood War (OpenBW)

Open-source reimplementation of the SC1/Brood War engine, pixel-accurate to
the original -- but worth the same "not a settled win" framing as the GemRB/
xoreos/FreeFT caveats elsewhere in this file: OpenBW has **no built-in
single-player AI** (skirmish/campaign opponents don't act on their own), and
the project is fundamentally oriented around AI-bot research/development via
BWAPI rather than a polished human single-player experience. Human-playable
options are narrower: a browser-based OpenBW build (casual 1v1 only) is the
more approachable route than the bot-development-focused native BWAPI build.
Multiplayer is capped at 1v1 and can't interop with retail StarCraft:
Remastered clients.

- Data: needs the original `STARDAT.MPQ`/`BROODAT.MPQ` -- **owned as a
  physical CD** here too, same manual-rip-then-local-store-path shape as
  Diablo/DevilutionX and the ScummVM trio above, not a `fetchGOG`/`fetchSteam`
  case.
- Given the no-built-in-AI and bot-research-first caveats, worth confirming
  the browser build actually covers "just play a casual game" before
  investing packaging effort in the native BWAPI-oriented build.

## Jak 3 (OpenGOAL, disc rip)

`open-goal/jak-project` decompiles and ports the whole original trilogy to
PC -- Jak 1 "considered in a polished, complete state for years," Jak 2 in
beta, **Jak 3 has a good amount of work left to do** but is playable.
Confirmed native on x86_64 Linux (also Windows, macOS via Rosetta), not
just Windows-plus-Proton.

- Explicit legal stance per the README: "Do not use this decompilation
  project without the use of your own legally purchased copy of the game" --
  supports every retail PAL/NTSC/NTSC-J build including Greatest Hits, but
  not the PS3/PS4/PS5 re-releases.
- **Owned copy is a physical disc** -- same manual-rip shape as every other
  disc-owned entry in this file: dump the ISO, drop its contents into
  `iso_data/jak3/` (per `task set-game-jak3`), then the project's own
  `task extract` / `task repl` -> `(mi)` / `task boot-game` pipeline handles
  the rest. Rip step becomes a local, hash-pinned source feeding that
  pipeline, not a `fetchGOG`/`fetchSteam` case.

## The Legend of Zelda: Twilight Princess (zeldaret/tp -- not playable yet)

Worth the same caveat framing as the GemRB/xoreos/FreeFT entries above
rather than a settled win: the GameCube release's code is **fully
matching** (100% decompiled to code that recompiles byte-identical to the
original), but per the project's own README this "is not, and will not,
produce a port, to PC or any other platform" -- it's a decompilation
artifact, not a runnable game on its own. Wii versions are still WIP
(aligning Debug, matching in progress).

- Build needs an owned disc image (`orig/GZ2E01`, ISO/RVZ/WIA/WBFS/CISO/
  NFS/GCZ/TGC all accepted, deletable after the initial build) -- **physical
  disc rip**, same shape as the other disc-owned entries in this file --
  but the payoff today is a bit-identical rebuilt binary, not a native
  Linux game to actually play. Linux is a supported *build* platform (via
  `wibo`, a 32-bit Windows binary wrapper) for producing that artifact, not
  evidence of a playable native port.
- Not worth pursuing as an install target today -- revisit if/when a real
  PC-port layer (Harbour Masters' Courage Reborn, or similar) builds on top
  of this decomp and actually produces something launchable.

## Unreal / Unreal Tournament / UT2004 (OldUnreal, disc rip)

OldUnreal (took over official maintenance from Epic in 2019) now ships
native Linux full-installers and ongoing patches for **Unreal (Gold)**,
**Unreal Tournament (99)**, and **Unreal Tournament 2004** -- actively
maintained, including a 2026 UT2004 patch overhauling Linux/macOS support
(x86_64/arm64/ppc64le, runs on a Raspberry Pi). **Unreal 2 has no native
port or reimplementation** -- skip it if it's part of the owned Anthology
bundle.

- OldUnreal's own full-installer scripts normally pull the original disc
  image from archive.org automatically -- **not needed here since the owned
  copies are physical CDs already**: same manual-rip-then-local-store-path
  shape as every other disc-owned entry above, feeding OldUnreal's patch
  layer directly instead of the archive.org download step.
- Nix shape: package OldUnreal's Linux installer/patch tarballs under
  `packages/` (not in nixpkgs currently), one per title (Unreal Gold, UT99,
  UT2004), same from-source-build category as KeeperFX/Xash3D-FWGS/TFE
  elsewhere in this file.

## Street Fighter X Mega Man

Official Capcom-published freeware crossover (Mega Man's cast, played as a
Street Fighter-style fighting/platformer hybrid, made for Mega Man's 25th/
Street Fighter's anniversary in 2012) -- unlike every fan-made entry in this
file, Capcom fully owns and still distributes this one directly, binary-only,
no source ever released.

- Distribution: still live on Capcom's own site
  (`megaman.capcom.com/sfxmm/sfxmm_dl_us.html`), direct `.zip` download,
  v2.0 (Jan 2013) -- also mirrored on Internet Archive
  (`archive.org/details/sf-x-mm`) as a hash-pinned fallback if Capcom's page
  ever disappears. Windows-only binary, no confirmed native Linux build.
- Nix shape: about as simple as this category gets -- a plain `fetchurl`
  against Capcom's stable direct-download URL (or the Archive.org mirror),
  unzip, wrap for Wine/Proton. No fetcher-infrastructure gap to fill, no mod
  ecosystem to track.

## Abobo's Big Adventure

Double Dragon/Mario/Zelda-esque NES mashup platformer -- originally an Adobe
Flash game (Flash reached EOL Dec 2020), but a standalone native build exists
separately from the `.swf`.

- Distribution: Internet Archive
  (`archive.org/details/abobos-big-adventure-flash-game`) hosts both the
  original `.swf` and native `.exe` builds; a community GitHub repo
  (`javiermisol/abobosbigadventure`) also ships packaged Linux/Windows builds
  via GitHub Releases. The original abobosbigadventure.com site is no longer
  the primary distribution point. Freeware, binary-only.
- Nix shape: prefer the native build (Archive.org or the GitHub releases)
  over the Flash version -- skips needing Ruffle (the Flash-emulation layer)
  entirely. Straightforward `fetchurl`/`fetchzip` against whichever host has
  the native build, no from-source build needed.

## Mariovania

Mario Metroidvania fangame (by KoBeWi), hosted on MFGG (Mario Fan Games
Galaxy) -- the site this repo doesn't have a fetcher for yet, unlike
GameBanana/ModDB/itch.io which already do.

- MFGG's download flow is opaque from the outside (no direct file URLs
  surfaced by search; the wiki page links through to an Internet Archive
  embed rather than a first-party direct link) -- worth checking the actual
  MFGG page/forum thread by hand before assuming a scrape pattern, but
  Archive.org (`archive.org/embed/Mariovania`) looks like the practical
  primary source regardless of what MFGG itself does.
- Nix shape: needs a new `lib/fetchers/mfgg.nix`, same `fetchHtmlThenCurl`
  shape as `moddb.nix`/`dosbox.nix` if MFGG's own download page turns out to
  be a real click-through gate -- worth building this fetcher generically
  (not Mariovania-specific) since MFGG is the de facto Mario-fangame hub and
  would cover future entries too, same spirit as `gamebanana.nix` already
  being shared infrastructure rather than single-use.
- Engine unconfirmed -- worth checking on download before writing the actual
  nix expression.

## Mushroom Kingdom Fusion

30+ franchise crossover platformer (Mario as the base game, levels/bosses/
assets pulled from Castlevania, Mega Man, Sonic, Halo, Doom, and dozens more)
-- cancelled once, open-sourced, then revived; actively updated again
(v0.93 Rev D, March 2026).

- Distribution: itch.io (`fusion-fangaming.itch.io`), GameMaker Studio build,
  freeware binary.
- Nix shape: `lib/fetchers/itch.nix` already covers this hosting directly --
  no new fetcher infrastructure needed, same pattern as the Ren'Py itch.io
  entries elsewhere in this file.

## Castlevania: The Lecarde Chronicles 2

Metroidvania sequel starring Eric Lecarde's son -- notable among the
fan-made entries in this file for being explicitly Konami-approved
(documented, not just fan lore), by Migami Games (2017).

- Distribution: source available on GitHub (`katriellucas/lecarde-2`) under
  freeware terms (no resale, derivatives stay free); Windows build mirrored
  on Uptodown and Internet Archive (`archive.org/details/lecarde-2`). Engine
  not confirmed from a source browse -- worth checking before packaging
  (GameMaker is the working assumption given the rest of this genre, not
  confirmed).
- Nix shape: lowest-friction fangame entry in this batch -- a real GitHub
  source repo plus an explicit legal green light, so this is a
  `fetchFromGitHub` + build (or `fetchurl` against the prebuilt Windows
  binary if building from source turns out not worth it) with no
  legal-risk caveat to carry, unlike most of the Castlevania-tribute
  fangames turned up in the wider search for this entry.

## Thrive

Original (not fan-derivative) open-source evolution/life-simulation game --
start as a single cell, evolve toward multicellular and beyond. Godot 4.7
(.NET/C# build), actively developed (commits as recent as July 2026).

- Distribution: GitHub releases (`Revolutionary-Games/Thrive`), also
  mirrored on itch.io and Steam. **Not currently packaged in nixpkgs** --
  would need a from-source build (Godot 4.7 .NET + C#, not the simpler
  GDScript-only case some other Godot titles would be) or packaging the
  prebuilt release binary directly, whichever turns out less painful once
  actually attempted.
- Real open-source project (GPL-family, matches this file's non-fangame OSS
  entries like OpenTTD/OpenRA) -- no legal caveats, just a packaging-effort
  question.

## NEO Scavenger

Post-apocalyptic survival RPG (Blue Bottle Games) -- built on Flixel/FlashDevelop,
so it's a genuine Flash (`.swf`) title, unlike the "Flash but has a native
build" shape of Abobo's Big Adventure above. No Steam Workshop/achievements
(dev has confirmed Flash doesn't cooperate with Steam's APIs), but a real
modding scene exists off-platform via the Blue Bottle Games forums.

- Runtime: needs testing whether Ruffle (already the assumed path for any
  Flash title in this repo, given Abobo's Big Adventure explicitly avoided
  it in favor of a native build) actually handles NEO Scavenger's `.swf`
  correctly -- unconfirmed here, worth a quick manual launch check before
  committing to this as the install path.
- Data: sold on both Steam [appid 248860] and GOG (`neo_scavenger`) -- no
  cross-platform key gifting between the two per the dev, so whichever
  storefront the owned copy is on picks `fetchSteam` vs `fetchGOG`; either
  extraction is otherwise the standard shape used throughout this file.
- Assets: has optimizable content (worth a size pass once the base install
  works, same spirit as this repo's existing asset-optimization tooling
  elsewhere -- not scoped further here).
- Mod support: "of sorts" -- no Workshop, no formal mod API, just
  community-shared file replacements/patches surfaced on the Blue Bottle
  Games and GOG forums. Would need manual survey of what a mod actually
  touches (data files vs `.swf` patching) before any nix-managed install-list
  idea (Ikemen/kart-racer style) could apply -- likely too unstructured for
  that pattern and closer to a "drop pre-patched files in" case.

## Freeciv

Original `freeciv.org` project (distinct from Freeciv21, the Longturn
community's separate Qt-based fork -- the two are parallel, both-maintained
projects, not a predecessor/successor relationship) -- turn-based 4X
civilization builder, GPL-2+.

- **Already packaged in nixpkgs** as `pkgs.freeciv` (currently tracking
  3.2.1, slightly behind upstream's 3.2.5) -- a `home.packages` add, no
  custom derivation work needed, same zero-effort shape as OpenTTD/OpenTyrian
  elsewhere in this file.
- No content-ecosystem angle worth tracking the way the kart-racer/Ikemen
  entries have -- ruleset variety is built into the base game (civ2civ3,
  classic, multiplayer rulesets) rather than needing external addon
  fetchers.

## Tales of Maj'Eyal

Turn-based fantasy roguelike RPG with a large persistent world, many playable
classes, talent trees, factions, lore, and permadeath. It is built around
exploration and highly configurable character builds rather than real-time
combat.

- Mod support: the official addon system supports new classes, races, zones,
  quests, talents, items, and complete gameplay alterations. Addons are
  distributed as `.teaa` archives through the official addon browser
  (`te4.org/addons`).
- Nix-managed install shape: package the native game once, fetch selected
  versioned addon archives as separate derivations, and install them into the
  game's writable addon directory through a generated profile or wrapper.
  Runtime saves and configuration must remain outside the store.
- Caveat: addons can depend on exact game versions and may contain mixed
  licenses or bundled assets, so each addon needs compatibility and
  redistribution review before being added.
- Sources: [official site](https://te4.org/) and
  [addon browser](https://te4.org/addons).

## Vampire: The Masquerade - Bloodlines

First-person narrative RPG about a newly embraced vampire navigating faction
politics, supernatural conspiracies, and personal quests in Los Angeles.
Dialogue choices, character disciplines, stealth, combat, and exploration all
support substantially different playthroughs.

- Mod support: the community has produced major repairs and expansions,
  including the Unofficial Patch, Clan Quest, The Final Nights, and Camarilla
  Edition. ModDB is the main organized source for many releases.
- Nix-managed install shape: fetch the owned Steam or GOG game data, fetch a
  selected patch or total-conversion archive, and expose a wrapper that
  launches the corresponding mod directory or profile. This would likely need
  more per-mod installation logic than the Doom WAD entries.
- Caveat: the game uses a Windows executable, proprietary data, installer-heavy
  mods, and strict base-patch assumptions. Linux runtime and exact mod
  compatibility need testing before committing to a shared package shape.
- Sources: [Steam](https://store.steampowered.com/app/2600/Vampire_The_Masquerade_Bloodlines/),
  [GOG](https://www.gog.com/en/game/vampire_the_masquerade_bloodlines), and
  [ModDB](https://www.moddb.com/games/vampire-the-masquerade-bloodlines/mods).

## Texture replacement on Linux

Texture replacement is a separate, useful game/modding direction. The key
distinction is between asset replacement, runtime GPU-texture replacement,
shader replacement, and post-processing. `vkBasalt`, Gamescope effects, and
ordinary ReShade presets alter the already-rendered frame; they do not replace
an individual game texture. RenderDoc and apitrace can inspect/export
resources, but are not persistent replacement loaders.

There is no universal Linux equivalent for arbitrary native OpenGL/Vulkan
games. A reliable implementation normally comes from the game/engine's own
resource loader, a game-specific mod loader, an emulator's texture cache, or a
Windows Direct3D wrapper running through Wine/Proton.

### Emulator shortlist

The following emulators have genuine dump-and-replace workflows rather than
only resolution scaling, shaders, filesystem mods, or texture inspection.

- **PPSSPP** -- strongest general candidate. Packs live at
  `~/.config/ppsspp/PSP/TEXTURES/<GAME_ID>/` on normal Linux SDL builds, or in
  the configured memstick. `textures.ini` supports versioning, `quick`,
  `xxh32`, and `xxh64` hashes, aliases/custom filenames, wildcard hash
  components, hash ranges, mip levels, ignored textures, and per-game INI
  overrides. PNG, DDS, KTX2, and ZIM are supported, with KTX2/DDS generally
  preferred for large packs. A `textures.zip` containing `textures.ini` is
  also supported. This is the best fit for a declarative pack library.
- **DuckStation** -- PS1 replacement under
  `~/.local/share/duckstation/textures/<SERIAL>/replacements/`, with dumps in
  the sibling `dumps/` directory. Per-game `config.yaml` supports detailed
  dumping/cache behavior and an `Aliases:` map that lets multiple source
  hashes use one replacement image. Current replacement scanning accepts PNG,
  JPEG, and WebP; filenames are generated from texture/palette hashes and VRAM
  upload metadata. Replacement textures are effectively single images rather
  than DDS-style mip chains.
- **Dolphin** -- mature GameCube/Wii support. Replacements are under
  `~/.local/share/dolphin-emu/Load/Textures/<GAMEID>/`, with dumps under
  `Dump/Textures/<GAMEID>/`. Current names contain dimensions, an XXH64 texture
  hash, optional palette hash, and the original format. PNG and DDS are
  accepted; a complete DDS mip chain is the safest choice when mipmaps matter.
  Current resource packs use `manifest.json`; a marker file named after the
  game ID selects a directory, but `Info.txt` is not a general metadata or
  alias format in current source.
- **Azahar** -- active Citra/Lime3DS successor with 3DS custom textures.
  Replacements are under
  `~/.local/share/azahar-emu/load/textures/<16-digit-title-ID>/`, with dumps in
  the corresponding `dump/textures/` tree. Current packs can contain
  `pack.json`, select new versus legacy CityHash64 behavior, and map hashes to
  alternate filenames or shared files. PNG, DDS, and KTX are supported,
  including normal-map material files. Legacy Citra/Lime3DS paths and hash
  conventions should not be assumed to be identical to Azahar's.
- **PCSX2** -- PS2 replacement under
  `~/.config/PCSX2/textures/<SERIAL>/replacements/`, with dumps in `dumps/`.
  The global `[Folders] Textures` setting in `PCSX2.ini` can redirect the
  complete texture root. Names contain texture hashes, optional CLUT hashes,
  region dimensions, and GS metadata. PNG and DDS are accepted; replacement
  mipmaps should normally be embedded in DDS rather than copied from the
  separate dumped `-mipN.png` files. There is no documented alias language.
- **Beetle PSX HW** -- RetroArch core-side replacement, Vulkan only. Enable
  `beetle_psx_hw_renderer = "hardware_vk"`, texture tracking, and texture
  replacement. Classic packs sit beside content in
  `<Game>-texture-replacements/` and use lowercase texture/palette CRC names
  such as `<texture-hash>-<palette-hash>.png`. Current source also has
  page-aligned modes, alternate texture directories, and more image formats,
  but 8-bit PNG is the safest portable format because it is what the official
  documentation guarantees.
- **GLideN64 / Mupen64Plus-Next** -- N64 high-resolution replacement through
  standalone Mupen64Plus or RetroArch. Unpacked packs use
  `hires_texture/<game-ident>/` and Rice-style names containing the game
  identifier, texture CRC, original format/size, and sometimes palette CRC.
  RetroArch normally uses
  `<system>/Mupen64plus/hires_texture/<game-ident>/`, with compiled `.htc` or
  `.hts` caches under `cache/`. Host/frontend path and game-ident behavior is
  more variable than the other emulators.
- **Flycast** -- Dreamcast, Naomi, Naomi 2, and Atomiswave replacement through
  game-ID directories and hexadecimal texture hashes. Standalone builds can
  use `Dreamcast.TexturePath` and `Dreamcast.TextureDumpPath`; the Libretro
  layout is normally `system/dc/textures/<game-id>/`. PNG/JPEG is established
  in released versions. Current development source adds DDS/BC7 and KTX2
  support, but native Linux renderer verification for those newer formats is
  weaker.

Useful upstream references:

- [PPSSPP texture replacement](https://www.ppsspp.org/docs/reference/texture-replacement/)
- [DuckStation texture replacement](https://github.com/stenzek/duckstation/wiki/Texture-Replacement)
- [Dolphin resource packs](https://github.com/dolphin-emu/dolphin/blob/master/docs/ResourcePacks.md)
- [Azahar](https://github.com/azahar-emu/azahar)
- [PCSX2](https://github.com/PCSX2/pcsx2)
- [Beetle PSX HW texture replacement](https://docs.libretro.com/library/beetle_psx_hw/#texture-replacements-vulkan-only)
- [Mupen64Plus-Next](https://docs.libretro.com/library/mupen64plus/)
- [Flycast](https://github.com/flyinghead/flycast)

### Systems not to count as generic replacement

- **Cemu** has graphic packs and debug texture dumping, but no external
  PNG/DDS runtime replacement system. Its `rules.txt` packs change resolution,
  texture allocation, shaders, patches, and virtual files.
- **Ryujinx** uses LayeredFS mods under
  `mods/contents/<TITLE_ID>/<mod>/romfs/`, which can replace the game's
  original texture resource files. That is useful file replacement, but not a
  hash-based runtime texture cache. The original project is discontinued;
  current fork behavior needs independent verification.
- **RPCS3** and **Xenia** have patches, captures, and debugging facilities but
  no documented general custom-texture replacement pipeline.
- **RetroArch** itself has no frontend-wide replacement feature. Replacement
  is implemented by individual cores, notably Beetle PSX HW and
  Mupen64Plus-Next.

### Windows tools under Wine/Proton

- **Special K** is the best first experiment for an offline Windows Direct3D
  game running through Proton. It can dump/load textures and has documented
  Wine/DXVK support; per-game configuration generally needs `UsingWINE=true`.
  Injection order, overlays, renderer choice, and game-specific support matter.
- **3Dmigoto** provides strong DX11 texture dumping/replacement and hash-based
  overrides, but is game-specific and only experimentally useful under Wine.
- **TexMod** is useful for older DirectX 9 games. It may work with a 32-bit
  Wine prefix, but its age and launcher/DLL quirks make it a fallback.
- **uMod** is a similarly inconsistent legacy option with support varying by
  fork and game.
- **Ninja Ripper** is primarily an extraction tool, not a persistent runtime
  replacement framework; Windows or a VM is the safer environment.
- **RenderDoc** and **apitrace** are valuable for discovering resource formats,
  draw calls, and hashes, but do not provide a normal replacement-pack
  workflow.

`DXVK` and `vkd3d-proton` do not themselves dump or replace textures; they
translate Direct3D to Vulkan. Windows DLL wrappers intercept on the Direct3D
side before translation, which explains why some Proton games work while
native Vulkan games do not. Do not use injection tools with protected online
games: anti-cheat can reject them regardless of whether the intended change is
cosmetic.

References:

- [Special K](https://github.com/SpecialKO/SpecialK)
- [3Dmigoto](https://github.com/bo3b/3Dmigoto)
- [TexMod](https://www.tzarsector.com/texmod/)
- [RenderDoc](https://github.com/baldurk/renderdoc)
- [apitrace](https://github.com/apitrace/apitrace)
- [DXVK](https://github.com/doitsujin/dxvk)
- [vkBasalt](https://github.com/DadSchoorse/vkBasalt)

### Native Linux alternatives

There is no mature general-purpose texture hook for arbitrary native Vulkan or
OpenGL games. Prefer the game's own asset/mod system:

- Minecraft Java resource packs.
- OpenMW's ordered `data=` directories.
- GZDoom WAD/PK3 replacement resources.
- Factorio ZIP mods and graphics API.
- Unity game-specific loaders, BepInEx plugins, or AssetBundles.
- Unreal game-specific `.pak` mods or loaders.

A custom Vulkan layer is theoretically possible through the loader layer API,
but Vulkan usually no longer knows the original asset filename. Compressed,
tiled, transient, bindless, and procedurally generated textures also make
identity and replacement difficult. Linux OpenGL interposition via
`LD_PRELOAD` is less standardized and generally requires per-game work.

### Nix management model

The most practical design is to keep finalized packs immutable and keep only
emulator state and authoring output mutable:

```text
Nix store:    versioned texture derivation
User data:    emulator settings, caches, and dump directories
Runtime:      symlink or managed files exposing the pack at its expected path
```

The pack-authoring workflow is inherently mutable: dump to a writable
directory, edit/convert the images, then package the finalized tree and expose
it with `home.file`, `xdg.dataFile`, or a wrapper. Do not point dumping at a
Nix-store path. Keep the entire emulator data directory writable where the
program creates settings, caches, or dump folders.

The strongest first targets for a shared Nix pattern are PPSSPP and
DuckStation because their pack formats explicitly support aliases and their
paths are predictable. Dolphin and Azahar are also good candidates. PCSX2,
Beetle PSX HW, GLideN64, and Flycast should be added as concrete packs justify
their frontend-specific configuration.

This repository currently has a RetroArch Flatpak reference but no emulator
texture-pack module. Start with one real, legally obtained pack and one
emulator before designing a shared helper. Pack licenses and the legality of
redistributing copyrighted replacement assets need checking per pack.
