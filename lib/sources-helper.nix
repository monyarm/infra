# Imported directly by sources.nix's own generated preamble. Takes no
# arguments (only uses builtins), so `import ./sources-helper.nix` works
# unapplied. `rec` so flattenPaths can call itself.
rec {
  # Resolves a pool-referencing list back to full records: each item is
  # either a string key into `pool` (reinjected under `keyField`), or an
  # already-full record.
  expandPool =
    keyField: pool:
    map (
      n:
      if builtins.isString n then
        (pool.${n} or (throw "sources.nix: unknown pooled entry ${n}")) // { ${keyField} = n; }
      else
        n
    );

  # Reconstructs a flat "/"-joined path list from a nested attrset keyed by
  # path segment. A value is one of: `null` (name is itself a leaf file),
  # a string (name is a directory containing exactly that one file), a
  # list of strings (name is a directory containing exactly those files,
  # no subdirectories), or another such attrset (name is a directory with
  # further nesting).
  flattenPaths =
    tree:
    builtins.concatMap (
      name:
      let
        value = tree.${name};
      in
      if value == null then
        [ name ]
      else if builtins.isString value then
        [ "${name}/${value}" ]
      else if builtins.isList value then
        map (f: "${name}/${f}") value
      else
        map (p: "${name}/${p}") (flattenPaths value)
    ) (builtins.attrNames tree);

  # Builtins-only split/join (no `lib` available here -- see file header).
  splitOn = sep: s: builtins.filter builtins.isString (builtins.split sep s);
  joinWith =
    sep: list: builtins.foldl' (acc: x: if acc == null then x else "${acc}${sep}${x}") null list;

  # "group:artifact:version[:classifier]" -> the Maven-layout relative
  # path. Matches lib/minecraft-prism-meta.nix's mavenCoordToPath and
  # update-sources.py's maven_coord_to_path.
  mavenCoordToPath =
    coord:
    let
      parts = splitOn ":" coord;
      group = builtins.elemAt parts 0;
      artifact = builtins.elemAt parts 1;
      version = builtins.elemAt parts 2;
      classifier = if builtins.length parts > 3 then "-" + builtins.elemAt parts 3 else "";
      groupPath = joinWith "/" (splitOn "\\." group);
    in
    "${groupPath}/${artifact}/${version}/${artifact}-${version}${classifier}.jar";

  mkMavenUrl = repoBase: coord: "${repoBase}${mavenCoordToPath coord}";

  # Matches update-sources.py's MAVEN_REPO_BASES.
  mavenRepoBases = {
    forge = "https://maven.minecraftforge.net/";
    forgeFiles = "https://files.minecraftforge.net/maven/";
    mojang = "https://libraries.minecraft.net/";
    fabric = "https://maven.fabricmc.net/";
    modmuss50 = "https://maven.modmuss50.me/";
    quilt = "https://maven.quiltmc.org/repository/release/";
    prism = "https://files.prismlauncher.org/maven/";
    central = "https://repo1.maven.org/maven2/";
  };

  # Reinjects a library record's `url` when update-sources.py replaced it
  # with a short repo code (see simplify_maven_record); records that kept
  # an explicit `url` pass through unchanged.
  resolveMavenLibrary =
    r:
    if r ? repo then
      (builtins.removeAttrs r [ "repo" ]) // { url = mkMavenUrl mavenRepoBases.${r.repo} r.name; }
    else
      r;

  # Reinjects a net.minecraft mainJar's `url` when update-sources.py
  # dropped it (see simplify_archive_org_main_jar); records that kept an
  # explicit `url` (the piston-data/launcher.mojang.com CDN cases, and the
  # irregular archive.org paths) pass through unchanged.
  resolveMainJar =
    mj:
    if mj ? url then
      mj
    else
      let
        version = builtins.elemAt (splitOn ":" mj.name) 2;
      in
      mj
      // {
        url = "https://archive.org/download/assets.minecraft.net-2013-11-13/assets.minecraft.net/${
          builtins.replaceStrings [ "." ] [ "_" ] version
        }/minecraft.jar";
      };

  # Reconstructs a directory's flat basename list from a mix of plain
  # leftover strings and {p,s,m} cluster specs (see cluster_path_list): a
  # cluster's m is the list of literal middles, each expanded back to
  # "${p}${middle}${s}".
  expandClusters =
    items:
    builtins.concatMap (
      item: if builtins.isString item then [ item ] else map (m: "${item.p}${m}${item.s}") item.m
    ) items;
}
