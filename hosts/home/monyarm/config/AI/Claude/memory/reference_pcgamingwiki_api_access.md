---
name: reference_pcgamingwiki_api_access
description: How to pull engine/release-date/cover data out of PCGamingWiki (MediaWiki action=query with rvsection=0 and a browser UA; Cargo API denied; image host redirect/hash quirks), verified 2026-11-16
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T19:10:12.619Z
---

PCGamingWiki as a bulk data source (verified 2026-11-16):

- The **Cargo API is not usable** from here (`action=cargoquery`-style calls come back permission-denied). The plain **MediaWiki `action=query`** endpoint *is* reachable — but only with a **browser User-Agent**; a default curl UA gets rejected.
- Best field source: raw wikitext of the lead section, i.e. `?action=query&prop=revisions&rvprop=content&rvslots=main&rvsection=0` — returns just the infobox. Read `{{Infobox game/row/engine|…}}` and `{{Infobox game/row/date|…}}` rows. ~40 titles fit per request (POST with pipe-separated titles), so a whole 1000+ library resolves in ~24 batches.
- Engine rows are frequently empty even when the game has an engine — a second pass by store-ID/name variants is needed (2026-11-16: 1112 candidates → 939 resolved pages → 764 with an engine row).
- `https://www.pcgamingwiki.com/wiki/ID_lookup` is the page for mapping Steam/GOG/Epic IDs to article names when a direct title lookup misses.
- **Cover images:** the infobox `cover` filename resolves under `https://www.pcgamingwiki.com/images/<x>/<xy>/<File>` which 302-redirects to `https://images.pcgamingwiki.com/…`. The hash directory in the article text can be **wrong/stale**: the first redirect target may 403 while a differently-hashed path (e.g. `e/e8/` vs `c/c1/`) returns 200. Always follow the redirect and, if it fails, try the alternate hash path before giving up.
