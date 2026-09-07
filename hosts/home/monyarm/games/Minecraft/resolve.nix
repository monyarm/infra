{
  lib,
  config,
  mkPrismInstance,
  pickModVersion,
  pickLatestByDate,
  autoMods,
  autoResourcePacks,
  autoDatapacks,
  autoModpacks,
  getComponent,
  loaderUidByKey,
  loaderFromDependencies,
  ...
}:
with lib;
let
  resolveModpackVersionEntry =
    project: version:
    let
      table = autoModpacks.${project} or (throw "games.minecraft: unknown modpack project ${project}");
    in
    if version == "latest" then
      pickLatestByDate table
    else
      table.${version} or (throw "games.minecraft: modpack ${project} has no version ${version}");

  # Custom modpacks are plain config, not a fetched package: minecraftVersion +
  # loader + a text-based mod list resolved against the explicit mods/
  # resourcePacks/datapacks registries (never against a modpack's own bundled
  # mods -- those are never promoted into the registry).
  isCustomModpack = def: def ? minecraftVersion;

  resolveCustomModpackMods =
    kind: table: def:
    mapAttrsToList (
      modName: selector:
      let
        modTable =
          table.${modName}
            or (throw "games.minecraft: ${modName} is not an explicitly registered ${kind} (add it under [modrinth] in sources.toml)");
      in
      pickModVersion {
        inherit modTable;
        inherit selector;
        inherit (def) minecraftVersion;
        inherit (def) loader;
      }
    ) (def.${kind} or { });
in
{
  # Resolves one games.minecraft.games.<name> definition into a concrete
  # PrismLauncher instance: picks the modpack version, resolves the loader
  # and any custom mod selectors, fetches the two prism-components needed
  # (net.minecraft + the loader, if any), and hands it all to mkPrismInstance.
  resolveGame =
    name: g:
    let
      modpackDef =
        if g.modpack == null then
          null
        else
          config.games.minecraft.modpacks.${g.modpack}
            or (throw "games.minecraft.games.${name}: unknown modpack ${g.modpack}");

      isCustom = modpackDef != null && isCustomModpack modpackDef;

      modrinthModpackEntry =
        if modpackDef != null && !isCustom then
          resolveModpackVersionEntry g.modpack g.modpackVersion
        else
          null;

      modpackTree = if modrinthModpackEntry != null then modrinthModpackEntry.package else null;

      modpackDependencies =
        if modrinthModpackEntry != null then
          modrinthModpackEntry.dependencies
        else if isCustom then
          { minecraft = modpackDef.minecraftVersion; }
        else
          { };

      loaderInfo = loaderFromDependencies modpackDependencies;

      minecraftVersion =
        if g.minecraftVersion != null then
          g.minecraftVersion
        else
          modpackDependencies.minecraft
            or (throw "games.minecraft.games.${name}: minecraftVersion is required when modpack is null");

      loader =
        if g.loader != null then
          g.loader
        else if isCustom then
          modpackDef.loader
        else if loaderInfo != null then
          loaderInfo.loader
        else
          null;

      loaderVersion =
        if g.loaderVersion != null then
          g.loaderVersion
        else if isCustom then
          modpackDef.loaderVersion
        else if loaderInfo != null then
          loaderInfo.loaderVersion
        else
          null;

      extraMods =
        g.mods ++ (if isCustom then resolveCustomModpackMods "mods" autoMods modpackDef else [ ]);
      extraResourcePacks =
        g.resourcePacks
        ++ (
          if isCustom then resolveCustomModpackMods "resourcePacks" autoResourcePacks modpackDef else [ ]
        );
      extraDatapacks =
        g.datapacks
        ++ (if isCustom then resolveCustomModpackMods "datapacks" autoDatapacks modpackDef else [ ]);

      minecraftComponent = getComponent "net.minecraft" minecraftVersion;
      loaderComponent =
        if loader == null then
          null
        else
          getComponent (loaderUidByKey.${loader}
            or (throw "games.minecraft.games.${name}: unknown loader ${loader}")
          ) loaderVersion;

      resolvedResourcePackOrder =
        if g.resourcePackOrder != null then
          g.resourcePackOrder
        else if modrinthModpackEntry != null then
          modrinthModpackEntry.resourcePackOrder
        else if isCustom then
          modpackDef.resourcePackOrder or null
        else
          null;
    in
    {
      components = [ minecraftComponent ] ++ optional (loaderComponent != null) loaderComponent;
      instance = mkPrismInstance {
        inherit
          name
          minecraftComponent
          loaderComponent
          modpackTree
          ;
        modpackFiles = if modrinthModpackEntry != null then modrinthModpackEntry.modpackFiles else [ ];
        overridesFiles = if modrinthModpackEntry != null then modrinthModpackEntry.overridesFiles else [ ];
        mods = extraMods;
        resourcePacks = extraResourcePacks;
        datapacks = extraDatapacks;
        inherit (g) configs files;
      };
      resourcePackOrder = resolvedResourcePackOrder;
    };
}
