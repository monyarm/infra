{
  lib,
  pkgs,
  fetchModrinth,
  mkModrinthPackTree,
  sources,
  ...
}:
with lib;
let
  minecraftSources = sources.minecraft or { };

  # A project's Modrinth-backed versions table, wrapped in the shape
  # pickModVersion expects: project -> versionKey -> { package; gameVersions; loaders; date; }.
  mkModTable =
    kind:
    mapAttrs (
      project: entry:
      mapAttrs (_versionKey: v: {
        package = fetchModrinth {
          inherit project;
          inherit (v) versionId;
          inherit (v) filename;
          sha256 = v.hash;
          # Without this, fetchModrinth's default name ("modrinth-${project}")
          # would land in mods/ with no .jar extension.
          name = v.filename;
        };
        inherit (v) gameVersions loaders date;
      }) entry.versions
    ) (filterAttrs (_: e: e.type == "modrinth") (minecraftSources.${kind} or { }));

  # prism-component registry entries, keyed by uid (one entry per component,
  # each holding every tracked version -- sources.toml registers just the
  # bare uid, e.g. "net.minecraft", not a specific version).
  componentsByUid = listToAttrs (
    map (e: nameValuePair e.uid e) (
      attrValues (
        filterAttrs (_: e: e.type == "prism-component" && e ? versions) (minecraftSources.libraries or { })
      )
    )
  );
in
{
  autoMods = mkModTable "mods";
  autoResourcePacks = mkModTable "resourcepacks";
  autoDatapacks = mkModTable "datapacks";

  # Modrinth-backed modpacks: project -> versionKey -> { package; date; dependencies; ... }.
  autoModpacks = mapAttrs (
    project: entry:
    mapAttrs (_versionKey: v: {
      package = mkModrinthPackTree {
        inherit project;
        versionRecord = v;
      };
      inherit (v) date dependencies;
      resourcePackOrder = v.resourcePackOrder or null;
      overridesFiles = v.overridesFiles or [ ];
      modpackFiles = map (f: {
        inherit (f) path;
        drv = pkgs.fetchurl {
          inherit (f) url;
          inherit (f) hash;
        };
      }) (v.files or [ ]);
    }) entry.versions
  ) (filterAttrs (_: e: e.type == "modrinth-modpack") (minecraftSources.modpacks or { }));

  getComponent =
    uid: version:
    let
      entry =
        componentsByUid.${uid}
          or (throw "games.minecraft: no [prism-component] registered for uid ${uid} -- add it to sources.toml and run update-sources.py.");
      versionRecord =
        entry.versions.${version}
          or (throw "games.minecraft: ${uid} has no tracked version ${version} -- run update-sources.py to pick up new releases.");
    in
    versionRecord // { inherit uid version; };

  # The single non-"minecraft" key in a modpack's `dependencies` object names
  # the loader, using Modrinth's *dependency-key* vocabulary -- which differs
  # from the bare loader names ("fabric", "quilt") used everywhere else
  # (a mod version's own `loaders` field, pickModVersion, and what a custom
  # modpack author writes in `loader`). Normalize to the bare vocabulary here
  # so downstream code only ever deals with one loader naming scheme.
  loaderUidByKey = {
    forge = "net.minecraftforge";
    fabric = "net.fabricmc.fabric-loader";
    quilt = "org.quiltmc.quilt-loader";
    neoforge = "net.neoforged";
  };
  loaderFromDependencies =
    deps:
    let
      loaderDependencyKeyToBareName = {
        forge = "forge";
        "fabric-loader" = "fabric";
        "quilt-loader" = "quilt";
        neoforge = "neoforge";
      };
      depKey = findFirst (k: deps ? ${k}) null (attrNames loaderDependencyKeyToBareName);
    in
    if depKey == null then
      null
    else
      {
        loader = loaderDependencyKeyToBareName.${depKey};
        loaderVersion = deps.${depKey};
      };

  pickLatestByDate =
    table:
    (foldlAttrs (
      best: _: e:
      if best == null || e.date > best.date then e else best
    ) null table);
}
