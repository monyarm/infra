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
  # validated against these.
  assetDims = {
    hero = {
      w = 1920;
      h = 622;
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
  };

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
    .game-card { background: #1c1e24; border: 1px solid #2a2c34; border-radius: 8px; padding: 1rem; }
    .game-card h3 { display: flex; justify-content: space-between; align-items: baseline; gap: 0.5rem; }
    .badge { font-size: 0.75rem; padding: 0.1rem 0.5rem; border-radius: 999px; background: #2a2c34; white-space: nowrap; }
    .badge.warn { background: #5b3a1a; color: #ffb870; }
    .assets { display: flex; flex-wrap: wrap; gap: 0.5rem; margin: 0.5rem 0; }
    .asset, .placeholder {
      box-sizing: border-box;
      width: 120px;
      height: 120px;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      border-radius: 4px;
    }
    .asset { background: #0d0e11; }
    .asset img { max-width: 100%; max-height: 100%; object-fit: contain; border-radius: 4px; }
    .placeholder {
      background: repeating-linear-gradient(45deg, #24262e, #24262e 6px, #1c1e24 6px, #1c1e24 12px);
      border: 1px dashed #3a3d47; font-size: 0.65rem; color: #8b8d98; padding: 0.25rem;
    }
    .tags { font-size: 0.8rem; color: #9a9ca6; margin: 0.25rem 0; }
    #collapse-toggle {
      background: #24262e; color: #e7e7ea; border: 1px solid #3a3d47; border-radius: 6px;
      padding: 0.4rem 0.9rem; font: inherit; cursor: pointer; margin-bottom: 1.5rem;
    }
    #collapse-toggle:hover { background: #2a2c34; }
    body.hide-fully-missing .game-card.fully-missing { display: none; }
  '';

  collapseToggleScript = count: ''
    document.getElementById('collapse-toggle').addEventListener('click', function () {
      var hidden = document.body.classList.toggle('hide-fully-missing');
      this.textContent = hidden
        ? 'Show ${toString count} fully-missing games'
        : 'Hide ${toString count} fully-missing games';
    });
  '';
in
gamesList: resolvePath:
let
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
  # one-game section of its own.
  categoryFor =
    g:
    let
      n = launcherPkgName g;
    in
    if n == null || (launcherCounts.${n} or 0) < 2 then "Other" else displayName n;

  categorized = lib.groupBy categoryFor gamesList;
  categoryNames =
    (lib.filter (k: k != "Other") (lib.attrNames categorized))
    ++ (lib.optional (categorized ? "Other") "Other");

  missingTypes = g: lib.filter (t: g.images.${t} == null) assetTypes;
  presentCountOf = g: (lib.length assetTypes) - (lib.length (missingTypes g));
  isFullyMissing = g: presentCountOf g == 0;
  hasNoCategories = g: g.tags == [ ];

  sumBy = f: lib.foldl' (a: g: a + f g) 0;

  fullyMissingCount = sumBy (g: if isFullyMissing g then 1 else 0) gamesList;

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
    in
    if img != null then
      [
        "div.asset"
        { }
        [
          "img"
          {
            src = resolvePath img;
            alt = "${g.name} ${t}";
            title = "${t} (${toString dims.w}x${toString dims.h})";
          }
        ]
      ]
    else
      [
        "div.asset.placeholder"
        {
          style = "aspect-ratio: ${toString dims.w} / ${toString dims.h};";
          title = "${t} missing (${toString dims.w}x${toString dims.h})";
        }
        [
          "span"
          "${t} missing"
        ]
      ];

  gameCard = g: [
    ("div.game-card" + lib.optionalString (isFullyMissing g) ".fully-missing")
    { }
    [
      "h3"
      { }
      [
        "span"
        g.name
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
        (parallel (map gameCard) games)
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
        "button#collapse-toggle"
        { type = "button"; }
        "Hide ${toString fullyMissingCount} fully-missing games"
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
        (niccup.raw (collapseToggleScript fullyMissingCount))
      ]
    ]
  ];

  html = "<!doctype html>\n" + niccup.renderPretty page;
in
{
  inherit json html;
}
