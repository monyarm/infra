# Next games: free / official-freeware / abandonware / physical-disc shortlist

Research report (2026-11-10). It covers what could feasibly be added next,
skipping heavy-mod engines (OpenMW, Daggerfall Unity) and Serious Sam (own
fork). The implementation plan for the picked subset (Diablo, three UZDoom
IWADs, ScummVM via archive.org) lives separately. Entries marked **[DONE]**
are implemented (2026-11-13): `DevilutionX/default.nix`,
`Doom/wad/{idgames,moddb}.nix`, `ScummVM/games/abandon.nix`.

Repo facts that shape the work:

- **No new "abandonware fetcher" needed for archive.org.**
  `ScummVM/games/direct.nix` already pulls archive.org items with plain
  `pkgs.fetchzip` (`hugo1`). `Doom/wad/` has `fetchIdGames`/moddb/itch
  fetchers.
- `game-library-scan --scummvm`: every GOG ScummVM match is already in
  `ScummVM/games/gog.nix`. Plain list mode still shows them because
  `already-defined.json` lacks their ids. That is a scanner nit, not game
  work.
- Physical discs go through `lib/fetchers/disc.nix` (`ripDiscContents`,
  `ripDisc`, `ripDiscRedumper`).

## 1. ScummVM abandonware

Source: the ScummVM 2026.4.0 compatibility list plus the wiki page "Where to
get the games". Store checks covered Steam and GOG only; Zoom, itch and Epic
were not checked. Every archive.org ID returned live metadata.

The full list of supported games marked "Available for Purchase: No" (252,
plus 28 with a blank purchase field) is in
`~/Documents/scummvm-not-purchasable.html`.

| Title | engine:id | archive.org item |
|---|---|---|
| **[DONE]** Discworld | tinsel:dw | `msdos_Discworld_1995` (CD talkie); `discwld_202204` is floppy-sized |
| **[DONE]** Discworld II | tinsel:dw2 | `msdos_Discworld_2_-_Missing_Presumed_1996`, `Discworld2UKDOS` (bin/cue) |
| The Neverhood | neverhood | `The_neverhood_ISO` |
| Nightlong: Union City Conspiracy | trecision:nl | `DreamCatcher_Nightlong_Win95_1998_Eng` |
| Woodruff and the Schnibble | gob:woodruff | `the-bizarre-adventures-of-woodruff-and-the-schnibble` |
| Ween: The Prophecy | gob:ween | `msdos_Ween_-_The_Prophecy_1993` |
| Urban Runner | gob:urban | `urbanrunnereurope` |
| Bargon Attack | gob:bargon | `msdos_Bargon_Attack_1992` |
| Cruise for a Corpse | cruise | `cruise-for-a-corpse` |
| Operation Stealth | cine:os | `james_bond_stealth_affair_loader` |
| Future Wars | cine:fw | `future-wars-adventures-in-time` (Steam name clash, verify) |
| Lost Files of Sherlock Holmes 1 / 2 | sherlock:scalpel / rosetattoo | `the-lost-files-of-sherlock-holmes-the-case-of-the-serrated-scalpel`, `The_lost_files_of_Sherlock_Holmes_Case_of_the_Rose_Tattoo_Electronic_Arts_1996` |
| Ringworld / Return to Ringworld / Blue Force | tsage | `RingworldCDDOS19931994`, `Return_to_Ringworld_1995_Time_Warner_Interactive`, `Blue_Force_1993_Tsunami` |
| Touché | touche | `msdos_Touche_-_The_Adventures_of_the_Fifth_Musketeer_1995` |
| Chewy: Esc from F5 | chewy | `chewy-esc-from-f5` |
| Bud Tucker in Double Trouble | tucker | `Bud_Tucker_in_Double_Trouble_1997_TopWare_DE` (German, find EN) |
| Hopkins FBI | hopkins | `Hopkins_FBI_BeOS_USA` |
| Hyperspace Delivery Boy! | hdb | `hyperspace-delivery-boy` (ixsoft status unverified) |
| Orion Burger | m4:burger | `msdos_Orion_Burger_1996` |
| **[DONE]** Duckman | illusions:duckman | `duckman-game-cd` |
| Beavis and Butt-Head: Virtual Stupidity | bbvs | `beavis-and-butt-head-in-virtual-stupidity_202208` |
| **[DONE]** Pink Panther 1 / 2 | pink:peril / pokus | `ThePinkPantherPassportToPerilUSA`, `ThePinkPantherHokusPokusPinkUSARerelease` / `the-pink-panther-hokus-pokus-pink-cd-rom-1998` |
| **[DONE]** Muppet Treasure Island | mtropolis:mti | `MuppetTreasureIslandPC` (MTI1-3.ISO) |
| Leather Goddesses of Phobos 2 | made:lgop2 | `msdos_Leather_Goddesses_of_Phobos_2_1992` |
| The Black Cauldron | agi:bc | `msdos_Black_Cauldron_The_1986` |
| Manhunter: New York | agi:mh1 | `msdos_Manhunter_1_-_New_York_1988` |
| Pepper's Adventures in Time | sci:pepper | `msdos_Peppers_Adventures_in_Time_1993` |
| Island of Dr. Brain | sci:islandbrain | `island-of-dr-brain` |
| Halls of the Dead (FTA II) | saga2:fta2 | `halls-of-the-dead` |
| Spaceship Warlock | director:warlock | `spaceshipwarlock_hybrid` |
| Versailles 1685 | cryomni3d:versailles | `msdos_Versailles_1685_1997` |
| Driller | freescape:driller | `driller-1989` |

Official freeware not yet in the repo (Nippon Safes, BS2.5 and hires1 are
already in): Lord Avalot d'Argent (avalanche), Mortville Manor (mortevielle,
from lankhor.net or archive.org `Mortville_Manor_1988_Lankhor`), Helga Deep
In Trouble, and the WAGE bundle (`downloads.scummvm.org/frs/extras/...`).

Excluded because they are still for sale: Rex Nebular, Zak McKracken,
Return to Zork, Elvira 1/2, Waxworks, Personal Nightmare, Feeble Files, the
Gobliiins pack, Code-Name: Iceman, Freddy Pharkas, Obsidian, Voyeur,
Hodj 'n' Podj (Zoom), Labyrinth of Time, Tony Tough, Toonstruck, Plumbers,
3 Skulls, Inherit the Earth, TLC, Pilot Brothers, Red Comrades, Mortadelo,
and Prince and the Coward.

myabandonware is the fallback when archive.org lacks a game. Its observed
flow: `/download/<code>-<slug>` returns 409 "Session required" without
cookies. With a Laravel session cookie (`maw4_session`) it returns 303 to
`/game/<slug>`. The final hop is still unobserved; the auto-mode classifier
blocked it.

## 2. UZDoom free IWADs

Source: UZDoom `wadsrc_extra/static/iwadinfo.txt`. Every non-id IWAD is an
official free release; no abandonware. Square, Action Doom 2, Blasphemer and
Chex are already in the repo.

- **[DONE] Hacx 1.2** `HACX.WAD`: idgames `themes/hacx/hacx12.zip`.
- **[DONE] Harmony Compatible** `HarmonyC.wad` + `Extra/Harm-WS.wad` on Doom II:
  idgames `levels/doom2/Ports/g-i/harmonyc.zip`. Supersedes standalone v1.1.
- **[DONE] Rise of the Wool Ball v1.3** `ROTWB.wad`: moddb download `125457`.
- Delaweare and Hacx 2.0 r61: no stable URL, skip.
- Heretic shareware, Hexen demo and Strife teaser: freely redistributable,
  but no stable URLs were found.

## 3. Raze: little to fetch (needs re-check)

Source: Raze master `wadsrc/static/engine/grpinfo.txt`. There is no
abandonware: every title and add-on is still buyable.

- Duke D.C., Caribbean, Nuclear Winter, Duke!ZONE II and Penthouse Paradise
  come as free bonus content in ZOOM's "Duke Nukem 3D: Atomic Edition". The
  Megaton Edition was delisted in 2016. These are not in the repo's World
  Tour copy.
- Blood + Cryptic Passage, Redneck x3, NAM, WWII GI and PowerSlave DOS are
  all on Steam or GOG.
- **Correction (user, citing the Duke wiki):** Duke Nukem's Penthouse
  Paradise is legally available for free, so it is a category-A
  candidate (Raze `Duke.PParadise`, needs the Atomic base GRP). The
  research agent wrongly counted it as "buyable". Re-verify the other Duke
  add-ons against the Duke wiki before treating Raze as done.
- Official free items (Duke3D shareware 1.3D, SW shareware, Powerslave demo,
  Nuclear Winter demo) are low value next to the owned full games.
- Platoon Leader is a free WWII GI add-on on indiedb. It only matters if
  WWII GI is bought.
- The only lever is buying the ZOOM Atomic Edition, Blood Fresh Supply, NAM
  or WWII GI.

### Duke add-ons re-uploaded to ModDB (checked 2026-11-10)

All were re-uploaded by community accounts on 2026-01-01 and 2026-01-02, at
`moddb.com/games/duke-nukem-3d/addons`.

- **Penthouse Paradise:** FREE-LEGAL, official 1997 freeware from
  Penthouse/GT Interactive. Raze `PENTHOUS.GRP`. It is the only one safe to
  fetch from ModDB.
- **Duke It Out in D.C.** (moddb 302224, "Public Domain" claim),
  **Caribbean** (302227), **Nuclear Winter** (302226), **Duke!ZONE II**,
  **Duke Assault** and **Duke Xtreme** are all still sold on ZOOM. Their
  re-uploads are probably unlicensed, so buy rather than fetch.
- The agent marked these as "in World Tour: yes". That contradicts the
  earlier Raze research, which said World Tour 434050 only adds Alien World
  Order. Verify against the actual depot before relying on it.

## 4. Physical collection (`~/Downloads/2026_11_10_ge_collection.csv`)

nixpkgs presence was checked against the flake registry pin, which may lag.

Playable now:

1. **[DONE] Diablo** (PC): DevilutionX 1.5.5 (`pkgs.devilutionx`). Only
   `DIABDAT.MPQ` from the disc is needed.
1. **Unreal Anthology**: OldUnreal UT99 469e (`pkgs.ut1999`) and UT2004 3374
   (`pkgs.ut2004`). UT2004 became an official free release in Feb 2026.
   Unreal 227k is in public beta, with no nixpkgs package.
1. **Zelda TP**: Dusklight (`TwilitRealm/dusklight`, `pkgs.dusklight`).
   **It now supports the Wii disc too** (user correction), so the owned Wii
   copy works.
1. **Jak 3** (PS2): OpenGOAL, Jak 3 beta since 2026-03-31. Not in nixpkgs.
1. **Mario Kart Wii** (Wii): recomp. The earlier "PAL-only Windows beta,
   repo unknown" claim was wrong (user correction); re-check its current
   state before planning.
1. **Halo CE** (Xbox): halo-re decomp port. The real repo is unclear and many
   lookalike forks exist.
1. **StarCraft + BW**: OpenBW. It has no SP AI.
1. **Icewind Dale EE**: GemRB 0.9.5 does not support IWDEE.

Beta, WIP or not applicable:

- Sims 1: Simitone, stale since 2023.
- Forsaken: ForsakenX uses free PC data, so the disc is irrelevant; it
  counts as a libre candidate.
- Uncharted NDC: native PC port, Windows-only.
- Bloodborne: bbport, experimental.
- Wii Sports: doldecomp/ogws is ~28% done.
- Croc: early decomp.
- Ty: GameCube decomp only.
- GTA III: re3 needs PC data.
- GoW II and Crazy Taxi: recomps target the PS3 versions, not the owned PS2
  discs.

Online services:

- City of Heroes: Homecoming is officially licensed.
- LBP2: Refresh/Beacon community servers.
- Guild Wars: official servers are still running.

No project was found for anything else in the collection.

## 5. Libre / non-Steam owned

- **OpenTyrian** (`pkgs.opentyrian`): Tyrian 2.1 is bundled freeware; GOG
  `tyrian_2000` is optional.
- **OpenRCT2** (`pkgs.openrct2`): set `rct2Path` from `fetchGOG rollercoaster_tycoon_deluxe`.
- **RefKeen Bio Menace**: the game is official freeware; GOG `bio_menace` is
  owned too.
- **Wargus / War1gus**: GOG-owned, from the candidate CSV.
- **KeeperFX**: GOG `dungeon_keeper`, not in nixpkgs.
- **Fully libre**: SRB2 and Ring Racers (`pkgs.srb2`, `pkgs.ringracers`),
  OpenTTD, Freeciv, SuperTuxKart, Forsaken (ForsakenX).

## 6. Owned library: open-source engines (osgameclones pass)

Method: osgameclones.com `remake`/`tool` entries marked playable or
semi-playable, intersected locally with the Steam/GOG/Epic library and the
physical CSV, then verified by an agent. Entries already in
`open-source-engine-candidates.csv` are not repeated here: OpenXcom,
dhewm3, OpenJK, TRX, Arx, iortcw/ET:Legacy, fallout-ce, KeeperFX, War1gus,
R.E.L.I.V.E. and doukutsu-rs. nixpkgs and status are per the agent; re-check
before packaging.

| Owned | Store | Project | Status | nixpkgs | Notes |
|---|---|---|---|---|---|
| Baldur's Gate EE / BG2 EE | Steam 228280 / 257350 | GemRB | 0.9.5 (2026-03): BG2EE "playable" per GamingOnLinux, earlier notes said experimental | `gemrb` | IWD EE still unsupported |
| Sonic Mania | Steam 584400 | RSDKModding/Sonic-Mania-Decompilation | working, Linux build, last commit 2026-05 | no | needs Steam data (`Data.rsdk`) |
| Star Wars JK: Dark Forces II | Steam 32380 | OpenJKDF2 | playable, native Linux | UNVERIFIED | |
| Knights and Merchants | Steam 253900 | KaM Remake | playable, 2026-09 fixes | no | |
| Dink Smallwood HD | GOG | GNU FreeDink | playable | `freedink` | original data also freeware |
| Prey (2006) | Steam 480490 | Prey2006 (id Tech 4 port) | active | no | |
| Duck Game | Steam 312530 | DuckGameRebuilt | active, last commit 2026-06 | no | .NET, runs on Proton, not native |
| KotOR / KotOR II | Steam 32370 / 208580 | reone | WIP, not finishable | no | |
| Amnesia: The Dark Descent | GOG / Steam 57300 | official HPL2 source release + community reworks | sporadic | no | |
| Half-Life | Steam 70 | FreeHL (FTE) | MP works, SP experimental | no | GAME_IDEAS already has Xash3D-FWGS |

False matches dropped: Fallout 4, BG3, FF X/X-2/XII, TR I/II/III name
collisions. Already covered: Doom/64, Wolf3D, ScummVM titles, Raze titles,
Morrowind, Daggerfall, Serious Sam.

## 7. Owned library: decomps, recomps and AI-made ports

Source catalogs, pulled and intersected locally (not from an agent's
memory): `myuu-151/awesome-decomp-games` `data/games.json` (1457 entries),
`wangxiaoxiang5599/recompiled-games-list` `data/recompiled-games.json` (363
entries) and `a-barzanti/ai-rebuilds` (81). An earlier agent pass invented
two repo URLs that returned 404, so only catalog-sourced URLs are used here.

Applies to the copy you own, most usable first:

| Owned | Platform | Project | Type / stage | Platforms |
|---|---|---|---|---|
| Burnout Dominator | PS2 | literalynn/BurnoutDominatorReversed | static recomp, **Working** | Windows, Linux |
| Mario Kart Wii | Wii | **patchzyy/Wiicompiled** (also chrissotraidis/kartpad, doldecomp/mkw) | static recomp, last commit 2026-10 | (check) |
| Zone of the Enders | PS2 | Yaz-Myst/ZOE-Recompiled | static recomp, Beta | Windows |
| Infamous Second Son | PS4 | HayatoG/iss_pc | game-specific runtime, Beta | Linux, Windows |
| GTA Vice City Stories | PS2 | gothamor/gta-vcs-recomp | static recomp, Early | Windows, Linux |
| Sonic Riders: Zero Gravity | PS2 | KidWizardOfTheWeb/SR2 | decomp, last commit 2026-09 | WIP |
| Summoner | PS2 (decomp is the PC version) | AARosson48/SummonerDecomp | decomp, 2026-10 | WIP, needs PC data |
| Wii Fit Plus | Wii | Tanline666/veryfat-dungeon | decomp, 2026-10 | WIP |
| Psychonauts | GOG / Steam | DrDecki/psychonauts-decomp | decomp, 2026-10 | WIP |
| LEGO Batman | Steam | wasdhjklxyz/lbtvg | decomp, 2026-10 | WIP |
| Resident Evil 2 | Steam | OpenBiohazard2 | engine remake, 2026-08 | WIP |
| Tomb Raider: Legend | Steam + PS2 | TheIndra55/cdcEngine | decomp, 2024-12 | WIP |
| Harry Potter CoS | GBA | cefege/harry-potter-2-chamber-of-secrets-pc | runtime, Early | Linux, Windows, Web |
| Fallout: New Vegas | Steam + PC disc | ieee802dot11ac/fnv (X360 decomp) | decomp, 2026-08 | WIP, X360 target |
| Hitman: Codename 47 | GOG / Steam | 0danny/re47 | decomp, **archived** | none |
| DBZ Budokai 2, LotR RotK, Bakugan, Bugs Bunny LiT | PS2/PS2/PS3/PC | dbz2, lotr-rotk, BakuganDotC-decomp, BugsDecomp | decomps, stale 2024-2025 | none |

Exists for a different version than the one you own, so not usable as-is:

- 007 NightFire: recomp of the Xbox version; you own PC.
- Crazy Taxi: X360 recomp, Early; you own Steam and PS2.
- Tekken 6: X360 recomp; you own PSP.
- MediEvil: PS1 recomps (Beta, Linux); you own the PS4 remake.
- Ratchet & Clank: PS2 decomps; you own the PS4 game.
- God of War II: PS3 HD recomp, macOS only.
- Half-Life 2: Xbox recomp, Early.
- Portal 2: recomp for macOS and iOS only.
- Persona 5 Royal: Switch-to-Android runtime.
- Terraria: PS3 decomp; you own Steam, which is native.
- Undertale: Xbox decomp; Steam is native anyway.
- Sonic Adventure DX/2: GameCube decomps.

Recomp launchers that apply to more than one game:

- SirDiabo/N64RecompLauncher (N64 only, and you own no N64 games).
- TechnicallyComputers/RetComM-Launcher (multi-console).
- mstan/recomp-ui (schema-driven generic frontend).
  All three URLs return 200; their features were not checked.
