---
name: reference-capcom-collection-extraction-tooling
description: Authoritative sources on Capcom collection ROM extraction (game-extraction-toolbox ROADMAP/FAQ, RED-Project issues, Steam guide 2997730346, aluigi QuickBMS scripts, MMZXLC mod loader), the dead-end threads proving D&D Chronicles of Mystara is unsolved, and how to dump Steam manifest file lists with DepotDownloader -manifest-only
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T18:34:18.407Z
---

Where to research whether a Capcom Steam collection still ships extractable ROMs (verified 2026-11-16):

- `shawngmc/game-extraction-toolbox` (GitHub, also on PyPI; in sources at ~line 709275) — its README/ROADMAP is the authority on which collections are solved. Currently supported: MMLC1, BNLC 1&2, MMXLC1 (X1–X3), CFC, Disney Afternoon, SADX GG. ROADMAP lists Zero/ZX, XLC2 and MMLC2 as known-but-unsolved; it also notes `X4 doesn't appear to be ROM based`. Its FAQ states flatly that the tool **will not hold decryption keys**, and its Street Fighter Alpha 2 case study documents the same missing-`.key` wall (their workaround: target an older MAME).
- `farmerbb/RED-Project` issue #174 — Castlevania Dominus Collection thread; states plainly that no ROM files can be extracted from the collection (native remaster reusing converted assets).
- Steam community guide **2997730346** — lists apps 495050, 743900, 999020 under "don't appear to have ROMs".
- `s3phir0th115/MMXLC1-Rom-Extractor` — the only Mega Man X extractor; **XLC1 only**, no XLC2 tool.
- Fast triage without downloading content: `direnv exec` + DepotDownloader `-manifest-only` (see reference_steam_manifest_only_listing) to dump a depot's filelist, then grep the manifest for `.bin/.iso/.cue/.gba/.nds` and console headers (`NTR-`, `TWL-`, `SLES_`, `PS-X EXE`) before committing to a download. Also useful: the repo's `scripts/prefetch/prefetch_steam.sh`.

D&D: Chronicles of Mystara (229480) — checked 2026-11-16, **nobody has published a solution**:
- ZenHAX thread **16017**: titled about `gfx.rom` / Chronicles of Mystara (2021) — one post, **zero replies**.
- forum.gamehacking.org thread **16315** (2017): wanting to patch the Hispanic ROMs into `main.rom`, stuck at "but I don't know how to handle with the encryption"; closes with "it seems nobody is really interesting in researching/hacking this collection."
- Steam discussions: people tried pulling `roms/` into MAME/WinKawaks and hit "two big files instead of multiple smaller ones as expected by Mame"; no method given.
- game-extraction-toolbox lists no D&D collection at all. Binding constraint is the 20-byte CPS2 key (`ddsom.key`, CRC `541e425d`) that MAME needs and the depot doesn't ship.
- Treat this as settled: don't re-run these searches; the remaining work is reversing `gfx.rom` swizzling / digging the key out of `ManaGame.exe`.

Format-level pointers for Mega Man Zero/ZX Legacy Collection (999020), verified 2026-11-16:

- aluigi's QuickBMS script `mega_man_zero_bin.bms` (`https://aluigi.altervista.org/bms/mega_man_zero_bin.bms`, mirrored in `aluigi/bms` on GitHub) documents the whole `*_z*.bin` container: `u32 count`, `count × u32 offset` where bit 31 = LZ77Wii-compressed, then payload; no filenames or addresses. It is a plain unpacker, not a ROM rebuilder.
- Modding scene references: StraDaMa's **MMZXLC-Mod-Loader** (overrides files under `nativePCx64/`, borrowed from chaudloader; pairs with Fluffy Manager 5000 mods) and **MMZC-GBA-Script-Restoration** (per-file script replacement) — both confirm an asset-loading port rather than an interpreter.
- Original GameFAQs threads and the ZenHAX thread on the `.bin` format (died unresolved) contain the community consensus: not emulation, assets load individually, no ROM swapping possible.
