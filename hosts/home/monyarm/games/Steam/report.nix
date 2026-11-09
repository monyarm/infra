{
  lib,
  niccup,
  parallel,
}:

let
  assetTypes = [
    "hero"
    "grid"
    "wide"
    "icon"
    "logo"
  ];

  # Steam's own reference dimensions per asset kind (SteamGridDB convention).
  # Only used to size/label placeholders -- real fetched assets aren't
  # validated against these. `logo` has no fixed target shape (it's a
  # variable-aspect transparent overlay, 1280x720 is just Steam's max
  # upload canvas, not a real aspect ratio) -- assetRatio below gives it a
  # neutral 1:1 box instead of this w/h pair.
  assetDims = {
    hero = {
      w = 1920;
      h = 620;
    };
    grid = {
      w = 600;
      h = 900;
    };
    wide = {
      w = 460;
      h = 215;
    };
    logo = {
      w = 1280;
      h = 720;
    };
    icon = {
      w = 32;
      h = 32;
    };
  };

  # Launcher package name -> display label for a category heading. Grouping
  # itself is fully dynamic (see categoryFor below): a brand-new launcher
  # family (e.g. a future ROM/libretro core) automatically gets its own
  # section once >=2 games use it, no code change needed here. Only add an
  # entry here if the raw package name would render badly as a heading.
  launcherDisplayNames = {
    uzdoom = "Doom";
    scummvm = "ScummVM";
    renpy = "Ren'Py";
  };

  # Launcher package names that get their own category section even with
  # just one game -- unlike a one-off emulator core sharing "Other" with
  # everything else singleton, these are a distinct enough engine/genre
  # (visual novels, ...) to deserve a labeled section from game #1.
  alwaysOwnCategory = [ "renpy" ];

  # `logo` has no fixed target shape (see assetDims comment above) -- shared
  # by assetSlot's per-card boxes and the modal CSS rules below, so both use
  # the exact same ratio per type.
  assetRatio =
    t: if t == "logo" then "1 / 1" else "${toString assetDims.${t}.w} / ${toString assetDims.${t}.h}";

  # The modal only ever shows one asset type per open, tagged onto
  # #sgdb-modal-grid's class by sgdbScript -- one rule per type, so a
  # searched hero doesn't end up squashed into a tall square with empty
  # space top/bottom like a generic 1:1 box would.
  modalTypeRules = lib.concatMapStringsSep "\n    " (
    t: ".sgdb-modal-grid.type-${t} > div { aspect-ratio: ${assetRatio t}; }"
  ) assetTypes;

  titlecase = s: lib.toUpper (lib.substring 0 1 s) + lib.substring 1 (-1) s;

  displayName = pkgName: launcherDisplayNames.${pkgName} or (titlecase pkgName);

  css = ''
    :root { color-scheme: dark; }
    body {
      margin: 0;
      padding: 2rem;
      background: #14151a;
      color: #e7e7ea;
      font: 15px/1.5 system-ui, sans-serif;
    }
    h1, h2, h3 { margin: 0 0 0.5rem 0; }
    .summary { margin-bottom: 2rem; }
    .stat-line { display: flex; justify-content: space-between; gap: 1rem; margin: 0.25rem 0; }
    .bar { background: #24262e; border-radius: 4px; height: 10px; overflow: hidden; margin: 0.25rem 0 1rem 0; }
    .bar > div { background: #5b9dfb; height: 100%; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 2rem; }
    th, td { text-align: left; padding: 0.35rem 0.75rem; border-bottom: 1px solid #24262e; }
    td .bar { margin: 0; width: 160px; }
    section { margin-bottom: 2.5rem; }
    .category-header { display: flex; align-items: baseline; gap: 1rem; flex-wrap: wrap; }
    .category-header span { color: #9a9ca6; font-size: 0.85rem; }
    .games { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 1rem; }
    .game-card { position: relative; background: #1c1e24; border: 1px solid #2a2c34; border-radius: 8px; padding: 1rem; }
    .game-card h3 { display: flex; justify-content: space-between; align-items: baseline; gap: 0.5rem; }
    /* A small ribbon-style corner button, peeking out over the card's own
       border rather than sharing the h3 row with the name/badges -- toggles
       "exhausted" (all findable art has been picked, the rest needs manual
       creation) so it stays visually distinct from the SteamGridDB badge. */
    .exhausted-toggle {
      position: absolute; top: -0.5rem; right: -0.5rem; width: 1.4rem; height: 1.4rem; padding: 0;
      border-radius: 50%; border: 1px solid #3a3d47; background: #24262e; color: #8b8d98;
      font-size: 0.7rem; line-height: 1; display: flex; align-items: center; justify-content: center;
      cursor: pointer; z-index: 1;
    }
    .exhausted-toggle:hover { background: #2a2c34; }
    .game-card.exhausted { border-color: #c9a227; }
    .game-card.exhausted .exhausted-toggle { background: #c9a227; border-color: #c9a227; color: #14151a; }
    body.hide-exhausted .game-card.exhausted { display: none; }
    .badge { font-size: 0.75rem; padding: 0.1rem 0.5rem; border-radius: 999px; background: #2a2c34; white-space: nowrap; }
    .badge.warn { background: #5b3a1a; color: #ffb870; }
    .assets { display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem; margin: 0.5rem 0; align-items: start; }
    .asset, .placeholder {
      box-sizing: border-box;
      width: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      border-radius: 4px;
      cursor: pointer;
    }
    .asset.type-hero, .placeholder.type-hero { grid-column: 1 / -1; }
    .asset { background: #0d0e11; }
    .asset img { max-width: 100%; max-height: 100%; object-fit: contain; border-radius: 4px; }
    .placeholder {
      background: repeating-linear-gradient(45deg, #24262e, #24262e 6px, #1c1e24 6px, #1c1e24 12px);
      border: 1px dashed #3a3d47; font-size: 0.65rem; color: #8b8d98; padding: 0.25rem;
    }
    .asset.picked, .placeholder.picked { outline: 2px solid #5b9dfb; }
    .tags { font-size: 0.8rem; color: #9a9ca6; margin: 0.25rem 0; }
    #collapse-toggle, #collapse-toggle-present, #sgdb-filter, #exhausted-filter, #sgdb-done, #sgdb-type-filter {
      background: #24262e; color: #e7e7ea; border: 1px solid #3a3d47; border-radius: 6px;
      padding: 0.4rem 0.9rem; font: inherit; cursor: pointer; margin-bottom: 1.5rem; margin-right: 0.5rem;
    }
    #collapse-toggle:hover, #collapse-toggle-present:hover, #sgdb-filter:hover, #exhausted-filter:hover, #sgdb-done:hover { background: #2a2c34; }
    body.sgdb-only .game-card:not(.sgdb-matched) { display: none; }
    /* Retargeted by sgdbScript to the currently selected asset type (or the
       whole-card fully-missing/fully-present classes when "All types" is
       selected) -- see refreshToggles(). */
    .game-card.toggle-hide-missing, .game-card.toggle-hide-present { display: none; }
    /* Only the selected asset type's slot stays visible across every card. */
    .asset.type-filtered-hidden, .placeholder.type-filtered-hidden { display: none; }
    /* A whole category section once every game in it is hidden by one of
       the toggles/filters above -- see updateSectionVisibility(). */
    section.sgdb-section-hidden { display: none; }
    .sgdb-badge { color: #5fb4f0; }
    .sgdb-modal-overlay {
      display: none; position: fixed; inset: 0; background: rgba(0, 0, 0, 0.6);
      align-items: center; justify-content: center; z-index: 10;
    }
    .sgdb-modal-overlay.open { display: flex; }
    .sgdb-modal {
      background: #1c1e24; border: 1px solid #2a2c34; border-radius: 8px;
      padding: 1rem; width: 80vw; max-height: 80vh; overflow: auto; box-sizing: border-box;
    }
    .sgdb-modal-close { cursor: pointer; float: right; }
    .sgdb-modal-search { display: flex; gap: 0.5rem; margin-bottom: 0.75rem; clear: both; }
    .sgdb-modal-search input {
      flex: 1; background: #14151a; color: #e7e7ea; border: 1px solid #3a3d47; border-radius: 6px;
      padding: 0.4rem 0.6rem; font: inherit;
    }
    .sgdb-modal-search button {
      background: #24262e; color: #e7e7ea; border: 1px solid #3a3d47; border-radius: 6px;
      padding: 0.4rem 0.8rem; font: inherit; cursor: pointer;
    }
    .sgdb-modal-search button:hover { background: #2a2c34; }
    .sgdb-modal-match { font-size: 0.8rem; color: #9a9ca6; margin: -0.4rem 0 0.75rem 0; clear: both; }
    .sgdb-modal-filters { display: flex; gap: 1rem; margin-bottom: 0.75rem; clear: both; font-size: 0.85rem; }
    .sgdb-modal-filters label { display: flex; align-items: center; gap: 0.3rem; cursor: pointer; }
    .sgdb-modal-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 0.5rem; }
    .sgdb-modal-grid > div { aspect-ratio: 1 / 1; }
    ${modalTypeRules}
    .sgdb-modal-grid > div.sgdb-hidden { display: none; }
    .sgdb-modal-grid img { width: 100%; height: 100%; cursor: pointer; border-radius: 4px; border: 1px solid #2a2c34; object-fit: contain; }
    .sgdb-modal-grid img:hover { border-color: #5b9dfb; }
  '';

  # Talks to steamgriddb-proxy.py (repo root) -- never calls SteamGridDB
  # directly, so no API key ever needs to reach this HTML (a world-readable
  # Nix store output). No template literals on purpose: this string is a
  # plain (non-interpolating) Nix '' ... '' literal, and JS `${}` would
  # collide with Nix's own interpolation syntax. All JS string literals use
  # double quotes -- a literal '' (adjacent single-quotes, e.g. JS's empty
  # string) would otherwise prematurely terminate this Nix string.
  sgdbScript = ''
    (function () {
      var BASE = "http://127.0.0.1:8743";
      var picks = {};
      try {
        var saved = localStorage.getItem("sgdbPicks");
        if (saved) picks = JSON.parse(saved);
      } catch (e) {}

      // appid -> true for cards marked "exhausted" (all findable art has
      // been picked, whatever's still missing needs manual creation).
      var exhausted = {};
      try {
        var savedExhausted = localStorage.getItem("sgdbExhausted");
        if (savedExhausted) exhausted = JSON.parse(savedExhausted);
      } catch (e) {}

      function pickKey(appid, type) {
        return appid + ":" + type;
      }

      // Marks the slot picked AND swaps its content for the chosen
      // thumbnail, so the report card itself visibly changes on pick, not
      // just a subtle outline.
      function applyPick(appid, type, thumb) {
        document.querySelectorAll(
          '.game-card[data-appid="' + appid + '"] [data-type="' + type + '"]'
        ).forEach(function (el) {
          el.classList.add("picked", "asset");
          el.classList.remove("placeholder");
          el.innerHTML = "";
          var img = document.createElement("img");
          img.src = thumb;
          img.alt = type + " (pending submit)";
          el.appendChild(img);
        });
      }

      function updateDoneButton() {
        var btn = document.getElementById("sgdb-done");
        var n = Object.keys(picks).length;
        btn.textContent = "Submit " + n + " SteamGridDB pick" + (n === 1 ? "" : "s");
      }

      Object.keys(picks).forEach(function (key) {
        applyPick(picks[key].appId, picks[key].type, picks[key].thumb);
      });
      updateDoneButton();

      var typeSelect = document.getElementById("sgdb-type-filter");
      var missingBtn = document.getElementById("collapse-toggle");
      var presentBtn = document.getElementById("collapse-toggle-present");
      var missingHidden = false;
      var presentHidden = false;

      function cardsWhere(type, wantPlaceholder) {
        if (type === "all") {
          return Array.prototype.slice.call(
            document.querySelectorAll(".game-card." + (wantPlaceholder ? "fully-missing" : "fully-present"))
          );
        }
        return Array.prototype.filter.call(document.querySelectorAll(".game-card"), function (card) {
          var slot = card.querySelector('[data-type="' + type + '"]');
          return !!slot && slot.classList.contains("placeholder") === wantPlaceholder;
        });
      }

      function applyTypeFilter() {
        var type = typeSelect.value;
        document.querySelectorAll("[data-type]").forEach(function (slot) {
          slot.classList.toggle("type-filtered-hidden", type !== "all" && slot.getAttribute("data-type") !== type);
        });
      }

      // A section (launcher category) hides entirely once every game card
      // in it is hidden by any active toggle/filter -- checked directly
      // against each card's current classes rather than tracked
      // separately, so it can never drift out of sync with them.
      function updateSectionVisibility() {
        var sgdbOnly = document.body.classList.contains("sgdb-only");
        var hideExhausted = document.body.classList.contains("hide-exhausted");
        document.querySelectorAll("section").forEach(function (section) {
          var anyVisible = Array.prototype.some.call(section.querySelectorAll(".game-card"), function (card) {
            if (card.classList.contains("toggle-hide-missing")) return false;
            if (card.classList.contains("toggle-hide-present")) return false;
            if (sgdbOnly && !card.classList.contains("sgdb-matched")) return false;
            if (hideExhausted && card.classList.contains("exhausted")) return false;
            return true;
          });
          section.classList.toggle("sgdb-section-hidden", !anyVisible);
        });
      }

      function refreshToggles() {
        var type = typeSelect.value;
        var missingCards = cardsWhere(type, true);
        var presentCards = cardsWhere(type, false);
        var suffix = type === "all" ? "games" : type + " slots";

        document.querySelectorAll(".game-card").forEach(function (card) {
          card.classList.remove("toggle-hide-missing", "toggle-hide-present");
        });
        if (missingHidden) missingCards.forEach(function (c) { c.classList.add("toggle-hide-missing"); });
        if (presentHidden) presentCards.forEach(function (c) { c.classList.add("toggle-hide-present"); });

        missingBtn.textContent = (missingHidden ? "Show " : "Hide ") + missingCards.length + " missing " + suffix;
        presentBtn.textContent = (presentHidden ? "Show " : "Hide ") + presentCards.length + " complete " + suffix;
        updateSectionVisibility();
      }

      typeSelect.addEventListener("change", function () {
        applyTypeFilter();
        refreshToggles();
      });
      missingBtn.addEventListener("click", function () {
        missingHidden = !missingHidden;
        refreshToggles();
      });
      presentBtn.addEventListener("click", function () {
        presentHidden = !presentHidden;
        refreshToggles();
      });
      refreshToggles();

      document.getElementById("sgdb-filter").addEventListener("click", function () {
        var on = document.body.classList.toggle("sgdb-only");
        this.textContent = on ? "Show all games" : "Show only SteamGridDB matches";
        updateSectionVisibility();
      });

      document.getElementById("exhausted-filter").addEventListener("click", function () {
        var on = document.body.classList.toggle("hide-exhausted");
        this.textContent = on ? "Show exhausted games" : "Hide exhausted games";
        updateSectionVisibility();
      });

      document.querySelectorAll(".game-card").forEach(function (card) {
        var appid = card.getAttribute("data-appid");
        card.classList.toggle("exhausted", !!exhausted[appid]);
        card.querySelector(".exhausted-toggle").addEventListener("click", function (e) {
          e.stopPropagation();
          exhausted[appid] = !exhausted[appid];
          if (!exhausted[appid]) delete exhausted[appid];
          localStorage.setItem("sgdbExhausted", JSON.stringify(exhausted));
          card.classList.toggle("exhausted", !!exhausted[appid]);
          updateSectionVisibility();
        });
      });

      document.querySelectorAll(".game-card").forEach(function (card) {
        var name = card.getAttribute("data-name") || "";
        fetch(BASE + "/lookup?name=" + encodeURIComponent(name))
          .then(function (r) { return r.json(); })
          .then(function (data) {
            if (data.found) {
              card.classList.add("sgdb-matched");
              var badge = card.querySelector(".sgdb-badge");
              if (badge) badge.textContent = "★";
            }
          })
          .catch(function () {});
      });

      var overlay = document.getElementById("sgdb-modal-overlay");
      var grid = document.getElementById("sgdb-modal-grid");
      var closeBtn = overlay.querySelector(".sgdb-modal-close");
      var filterInputs = document.querySelectorAll("#sgdb-modal-filters input[data-filter]");

      function closeModal() {
        overlay.classList.remove("open");
      }

      // A "regular" item (neither flag set) shows only via the regular
      // checkbox; an item flagged nsfw and/or humor shows if either of its
      // matching checkboxes is on (inclusive -- an nsfw+humor item isn't
      // hidden just because one of the two is unchecked).
      function itemVisible(nsfw, humor, filters) {
        if (!nsfw && !humor) return filters.regular;
        return (nsfw && filters.nsfw) || (humor && filters.humor);
      }

      function currentFilters() {
        var f = {};
        filterInputs.forEach(function (cb) {
          f[cb.getAttribute("data-filter")] = cb.checked;
        });
        return f;
      }

      function applyModalFilters() {
        var filters = currentFilters();
        grid.querySelectorAll(":scope > div").forEach(function (wrap) {
          var visible = itemVisible(
            wrap.getAttribute("data-nsfw") === "true",
            wrap.getAttribute("data-humor") === "true",
            filters
          );
          wrap.classList.toggle("sgdb-hidden", !visible);
        });
      }

      filterInputs.forEach(function (cb) {
        cb.addEventListener("change", applyModalFilters);
      });

      // Set by openModal, read by runSearch's result-click handler -- the
      // *pick* always targets the game/slot the modal was opened for, even
      // when the search box (magnifying glass) is used to look up a
      // different game's art (wrong name match, or borrowing a
      // franchise-mate's icon/hero).
      var currentAppid = null;
      var currentName = null;
      var currentFile = null;
      var currentType = null;
      var searchInput = document.getElementById("sgdb-modal-search-input");
      var matchLabel = document.getElementById("sgdb-modal-match");

      function runSearch(searchName) {
        grid.className = "sgdb-modal-grid type-" + currentType;
        grid.innerHTML = "Loading...";
        matchLabel.textContent = "";
        fetch(BASE + "/search?name=" + encodeURIComponent(searchName) + "&type=" + encodeURIComponent(currentType))
          .then(function (r) { return r.json(); })
          .then(function (data) {
            matchLabel.textContent = data.matchedName
              ? "Matched: " + data.matchedName
              : "No SteamGridDB match found for this name";
            grid.innerHTML = "";
            data.results.forEach(function (item) {
              // Shows the same dashed placeholder look as the report cards
              // until the thumbnail actually loads, instead of a blank gap.
              var wrap = document.createElement("div");
              wrap.className = "placeholder";
              wrap.setAttribute("data-nsfw", String(!!item.nsfw));
              wrap.setAttribute("data-humor", String(!!item.humor));
              var img = document.createElement("img");
              img.addEventListener("load", function () { wrap.classList.remove("placeholder"); });
              img.addEventListener("error", function () { wrap.classList.remove("placeholder"); });
              img.addEventListener("click", function () {
                picks[pickKey(currentAppid, currentType)] = {
                  appId: currentAppid, name: currentName, file: currentFile, type: currentType,
                  url: item.url, thumb: item.thumb
                };
                localStorage.setItem("sgdbPicks", JSON.stringify(picks));
                applyPick(currentAppid, currentType, item.thumb);
                updateDoneButton();
                closeModal();
                // Fire-and-forget: starts fetching+hashing this image now
                // instead of waiting until Submit, so /submit can usually
                // just read an already-computed hash back.
                fetch(BASE + "/prefetch?url=" + encodeURIComponent(item.url)).catch(function () {});
              });
              img.src = item.thumb;
              wrap.appendChild(img);
              grid.appendChild(wrap);
            });
            applyModalFilters();
          })
          .catch(function () {
            grid.textContent = "Search failed (is steamgriddb-proxy.py running?)";
          });
      }

      function openModal(appid, name, file, type) {
        currentAppid = appid;
        currentName = name;
        currentFile = file;
        currentType = type;
        searchInput.value = name;
        overlay.classList.add("open");
        runSearch(name);
      }

      document.getElementById("sgdb-modal-search").addEventListener("submit", function (e) {
        e.preventDefault();
        runSearch(searchInput.value.trim() || currentName);
      });

      closeBtn.addEventListener("click", closeModal);
      overlay.addEventListener("click", function (e) {
        if (e.target === overlay) closeModal();
      });

      document.querySelectorAll(".asset, .placeholder").forEach(function (slot) {
        slot.addEventListener("click", function () {
          var card = slot.closest(".game-card");
          openModal(
            card.getAttribute("data-appid"),
            card.getAttribute("data-name"),
            card.getAttribute("data-file"),
            slot.getAttribute("data-type")
          );
        });
      });

      document.getElementById("sgdb-done").addEventListener("click", function () {
        var btn = this;
        var n = Object.keys(picks).length;
        if (n === 0) return;
        if (!confirm("Submit " + n + " SteamGridDB pick" + (n === 1 ? "" : "s") + "?")) return;
        fetch(BASE + "/submit", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(Object.keys(picks).map(function (k) { return picks[k]; }))
        })
          .then(function () {
            picks = {};
            localStorage.removeItem("sgdbPicks");
            btn.textContent = "Submitted " + n + " picks";
            updateDoneButton();
          })
          .catch(function () { btn.textContent = "Submit failed"; });
      });
    })();
  '';
in
gamesList: resolvePath: gameFinalArgs:
let
  # For "nix build" scripts / manual testing: a full shell-ready launch
  # command, not just the bare exe (a launcher-wrapped game needs the
  # launcher's own args and the game path passed to it too).
  gameCommand = g: ''cd "${g.workingDirectory}" && "${g.resolvedTargetExe}" ${gameFinalArgs g}'';

  launcherPkgName = g: if g.launcher != null then lib.getName g.launcher.package else null;

  launcherCounts = lib.foldl' (
    acc: g:
    let
      n = launcherPkgName g;
    in
    if n == null then acc else acc // { ${n} = (acc.${n} or 0) + 1; }
  ) { } gamesList;

  # A game whose launcher is used by only itself (a "singleton" launcher), or
  # has no launcher at all, lands in "Other" instead of getting a
  # one-game section of its own -- unless it's in alwaysOwnCategory.
  categoryFor =
    g:
    let
      n = launcherPkgName g;
    in
    if n == null then
      "Other"
    else if (launcherCounts.${n} or 0) < 2 && !(builtins.elem n alwaysOwnCategory) then
      "Other"
    else
      displayName n;

  categorized = lib.groupBy categoryFor gamesList;
  categoryNames =
    (lib.filter (k: k != "Other") (lib.attrNames categorized))
    ++ (lib.optional (categorized ? "Other") "Other");

  missingTypes = g: lib.filter (t: g.images.${t} == null) assetTypes;
  presentCountOf = g: (lib.length assetTypes) - (lib.length (missingTypes g));
  isFullyMissing = g: presentCountOf g == 0;
  isFullyPresent = g: presentCountOf g == lib.length assetTypes;
  hasNoCategories = g: g.tags == [ ];

  sumBy = f: lib.foldl' (a: g: a + f g) 0;

  assetStats = games: {
    total = (lib.length games) * (lib.length assetTypes);
    missing = sumBy (g: lib.length (missingTypes g)) games;
  };

  tagStats = games: {
    total = lib.length games;
    missing = sumBy (g: if hasNoCategories g then 1 else 0) games;
  };

  overallAssetStats = assetStats gamesList;
  overallTagStats = tagStats gamesList;
  perTypeStats = lib.genAttrs assetTypes (t: {
    total = lib.length gamesList;
    missing = sumBy (g: if g.images.${t} == null then 1 else 0) gamesList;
  });

  pct = s: if s.total == 0 then 100 else ((s.total - s.missing) * 100) / s.total;
  presentOf = s: s.total - s.missing;

  # --- Combined JSON -------------------------------------------------------
  gameJson = g: {
    inherit (g) appId name tags;
    category = categoryFor g;
    missing = missingTypes g;
    images = lib.mapAttrs (_: resolvePath) g.images;
    command = gameCommand g;
  };

  json = builtins.toJSON (parallel (map gameJson) gamesList);

  # --- HTML (niccup) ---------------------------------------------------
  progressBar = stats: [
    "div.bar"
    { }
    [
      "div"
      { style = "width: ${toString (pct stats)}%"; }
    ]
  ];

  statLine = label: stats: [
    "div.stat-line"
    { }
    [
      "span"
      label
    ]
    [
      "span"
      "${toString (presentOf stats)}/${toString stats.total} (${toString (pct stats)}%)"
    ]
  ];

  assetSlot =
    g: t:
    let
      img = g.images.${t};
      dims = assetDims.${t};
      ratio = "aspect-ratio: ${assetRatio t};";
      # hero is the widest, shortest asset by far -- spans the full row
      # instead of squeezing into one of the two columns like the others.
      spanClass = lib.optionalString (t == "hero") ".type-hero";
    in
    if img != null then
      [
        ("div.asset" + spanClass)
        {
          style = ratio;
          "data-type" = t;
          title = "${t} (${toString dims.w}x${toString dims.h})";
        }
        [
          "img"
          {
            src = resolvePath img;
            alt = "${g.name} ${t}";
          }
        ]
      ]
    else
      [
        ("div.asset.placeholder" + spanClass)
        {
          style = ratio;
          "data-type" = t;
          title = "${t} missing (${toString dims.w}x${toString dims.h})";
        }
        [
          "span"
          "${t} missing"
        ]
      ];

  gameCard = g: [
    (
      "div.game-card"
      + lib.optionalString (isFullyMissing g) ".fully-missing"
      + lib.optionalString (isFullyPresent g) ".fully-present"
    )
    {
      "data-appid" = toString g.appId;
      "data-name" = g.name;
      "data-file" = if g.sourceFile != null then g.sourceFile else "";
    }
    [
      "button.exhausted-toggle"
      {
        type = "button";
        title = "Toggle exhausted (all findable art picked, rest is manual)";
      }
      "✓"
    ]
    [
      "h3"
      { }
      [
        "span"
        g.name
      ]
      [
        "span.sgdb-badge"
        { }
      ]
      [
        "span.badge"
        "${toString (presentCountOf g)}/${toString (lib.length assetTypes)}"
      ]
    ]
    [
      "div.tags"
      { }
      (
        if hasNoCategories g then
          [
            "span.badge.warn"
            "no categories!"
          ]
        else
          "Categories: " + lib.concatStringsSep ", " g.tags
      )
    ]
    [
      "div.assets"
      { }
      (map (t: assetSlot g t) assetTypes)
    ]
  ];

  categorySection =
    cat:
    let
      games = categorized.${cat};
      aStats = assetStats games;
      tStats = tagStats games;
    in
    [
      "section"
      { }
      [
        "div.category-header"
        { }
        [
          "h2"
          cat
        ]
        [
          "span"
          "${toString aStats.missing} assets missing"
        ]
        [
          "span"
          "${toString tStats.missing} games missing categories"
        ]
      ]
      (progressBar aStats)
      [
        "div.games"
        { }
        # cards rendered to strings in parallel; forcing
        # the rendered strings is what parallelizes, not the node trees
        (
          let
            cards = map (g: niccup.render (gameCard g)) games;
          in
          builtins.parallel cards (map niccup.raw cards)
        )
      ]
    ];

  typeTableRow = t: [
    "tr"
    { }
    [
      "td"
      t
    ]
    [
      "td"
      "${toString (presentOf perTypeStats.${t})}/${toString perTypeStats.${t}.total}"
    ]
    [
      "td"
      { }
      (progressBar perTypeStats.${t})
    ]
  ];

  page = [
    "html"
    { lang = "en"; }
    [
      "head"
      { }
      [
        "meta"
        { charset = "utf-8"; }
      ]
      [
        "title"
        "Steam library artwork report"
      ]
      [
        "style"
        (niccup.raw css)
      ]
    ]
    [
      "body"
      { }
      [
        "h1"
        "Steam library artwork report"
      ]
      [
        "select#sgdb-type-filter"
        { }
        (
          [
            [
              "option"
              { value = "all"; }
              "All types"
            ]
          ]
          ++ map (t: [
            "option"
            { value = t; }
            (titlecase t)
          ]) assetTypes
        )
      ]
      [
        "button#collapse-toggle"
        { type = "button"; }
        ""
      ]
      [
        "button#collapse-toggle-present"
        { type = "button"; }
        ""
      ]
      [
        "button#sgdb-filter"
        { type = "button"; }
        "Show only SteamGridDB matches"
      ]
      [
        "button#exhausted-filter"
        { type = "button"; }
        "Hide exhausted games"
      ]
      [
        "button#sgdb-done"
        { type = "button"; }
        "Submit SteamGridDB picks"
      ]
      [
        "div#sgdb-modal-overlay.sgdb-modal-overlay"
        { }
        [
          "div.sgdb-modal"
          { }
          [
            "span.sgdb-modal-close"
            { }
            "×"
          ]
          [
            "form#sgdb-modal-search.sgdb-modal-search"
            { }
            [
              "input"
              {
                type = "text";
                id = "sgdb-modal-search-input";
                placeholder = "Search a different game's art (e.g. a franchise-mate, or if the name matched wrong)...";
              }
            ]
            [
              "button"
              { type = "submit"; }
              "🔍"
            ]
          ]
          [
            "div#sgdb-modal-match.sgdb-modal-match"
            { }
          ]
          [
            "div#sgdb-modal-filters.sgdb-modal-filters"
            { }
            [
              "label"
              { }
              [
                "input"
                {
                  type = "checkbox";
                  checked = true;
                  "data-filter" = "regular";
                }
              ]
              "Regular"
            ]
            [
              "label"
              { }
              [
                "input"
                {
                  type = "checkbox";
                  checked = true;
                  "data-filter" = "nsfw";
                }
              ]
              "NSFW"
            ]
            [
              "label"
              { }
              [
                "input"
                {
                  type = "checkbox";
                  checked = true;
                  "data-filter" = "humor";
                }
              ]
              "Joke/Humor"
            ]
          ]
          [
            "div#sgdb-modal-grid.sgdb-modal-grid"
            { }
          ]
        ]
      ]
      [
        "div.summary"
        { }
        (statLine "Assets present" overallAssetStats)
        (progressBar overallAssetStats)
        (statLine "Games with categories" overallTagStats)
        (progressBar overallTagStats)
        [
          "table"
          { }
          [
            "thead"
            { }
            [
              "tr"
              { }
              [
                "th"
                "Asset type"
              ]
              [
                "th"
                "Present"
              ]
              [
                "th"
                ""
              ]
            ]
          ]
          [
            "tbody"
            { }
            (map typeTableRow assetTypes)
          ]
        ]
      ]
      (map categorySection categoryNames)
      [
        "script"
        (niccup.raw sgdbScript)
      ]
    ]
  ];

  html = "<!doctype html>\n" + niccup.renderPretty page;
in
{
  inherit json html;
}
