---
name: project-tr-steam-depot-contents
description: Confirmed Steam depot layouts for Tomb Raider I/II/III (224960/225300/225320), the extraction/renaming steps TRX packaging needs, and that none of them include expansion levels
metadata:
  type: project
  origin: opencode
  modified: 2026-11-13T18:08:34.651Z
---

Verified Steam depot contents for the three Tomb Raider apps (manifest-only listing, 2026-11-13):

- **224960 Tomb Raider I** — depot 224961, manifest 1018039351833983427 (2020-03-13), 147 files / 318 MB. It is a GOG DOSBox repack: `GAME.GOG` (282 MB, ISO 9660 CD-ROM Mode 1 with 2352-byte sectors), `GAME.DAT` (590 B ASCII wrapper metadata), `TOMBRAID/` holding only `tomb.exe`/`TOMB.SP`/`SETTINGS.DAT`, plus dosbox/gogwrap/GLIDE dlls, `DOCS/`, `SHADERS/`, `manuals/`, and 9 soundtrack tracks `02.mp3`..`10.mp3` at depot root. All game data is inside the ISO image: 21 `DATA/*.PHD` (level1..8c, level10a..10c, gym, title, cut1..4) and 11 `FMV/*.RPL` (cafe, canyon, core, end, escape, lift, mansion, prison, pyramid, snow, vision). No `core.avi` — only `FMV/CORE.RPL`.
  - Extraction needs two steps in the derivation: strip 2352-byte sectors to a plain 2048-byte ISO, then `7z x` (7z on the raw image fails, verified).
  - Music ships as mp3 at depot root; **no transcode needed** — TRX plays mp3 natively. Only a rename `02.mp3`..`10.mp3` → `track02.mp3`..`track10.mp3` is required (pure rename, no ffmpeg in the derivation).
- **225300 Tomb Raider II** — depot 225301, manifest 1701443328413221856 (2012-11-08), 144 files / 349 MB, normal loose DOS layout: 24 `data/*.TR2`, `data/MAIN.SFX`, 8 `fmv/*.RPL`, and 60 tracks `music/2.mp3`..`music/61.mp3` with bare numbers (no `track` prefix); `audio/cdaudio.mp3` (42 MB) + `cdaudio.dat` are a redundant full-disc rip.
- **225320 Tomb Raider III** — depot 225321, manifest 5659119167172291423 (2012-11-08), 83 files / 490 MB: 20 `data/*.TR2` + `TITLE.TR2`, `cuts/CUT1..12.TR2`, `data/MAIN.SFX`, 239 MB `audio/cdaudio.wad` (music inside, usable as-is), 5 `fmv/` (Crsh_Eng, Endgame, Intr_Eng, logo, Sail_Eng).

TR1 came from the 2020 GOG repack while TR2/3 are 2012 DOS uploads — that is why only TR1 is CD-image-wrapped.

**No expansion content in any of the three depots** (verified against the manifests): TR1 has no Unfinished Business levels, TR2's 24 `.TR2` = 18 base + title + `cut1..4` with no Gold levels, TR3 has no Lost Artefact levels. Supporting them would need separate purchases, as separate game dirs (`games/tr1-ub`, `tr2-gm`, `tr3-la`).

**Why:** These layouts determined the data-prep tasks in the now-deleted `.claude/plans/tomb-raider-trx.md`; the TR1 wrapper makes it far more than a plain copy.

**How to apply:** When implementing the TRX game module, use the per-title steps above instead of assuming a uniform unpack. Resolver behaviour read from TRX source (`src/trx/game/music/backend_files.c`):
- Track extensions tried in order: `.flac`, `.ogg`, `.mp3`, `.wav`, `.wma` — mp3 is first-class, and flac is only preferred when both formats are present. So do not transcode the depot mp3s.
- Candidate names are built as catalog row → `dir/track%02d.ext` → `dir/%d.ext`. TR2's bare `music/2.mp3` matches the `%d` form exactly, so the TR2 tracks work **as-is, no rename** (an earlier assumption that they needed renaming was wrong). TR1's zero-padded `02.mp3` matches neither pattern, hence the `trackNN` rename.
- `FMV/CORE.RPL` needs no handling either: `src/trx/game/fmv.c` probes `.mp4`, `.mpeg`, `.webm`, `.avi`, `.fmv`, `.rpl` by basename, so the `core` movie loads directly; the `core.avi` seen in docs is just another release's extension for the same movie.

Unverified: no real TRX launch was run — the TR1 `02.mp3` → `track02.mp3` rename is inferred from the resolver code, not observed.
