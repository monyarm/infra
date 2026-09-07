{
  lib,
  pkgs,
  config,
  dirs,
  mkOutOfStoreSymlink,
  mkModDir,
  mkPrismComponentPatch,
  mkMmcPackComponent,
  mkPrismComponentLibraries,
  fetchModrinth,
  mkModrinthPackTree,
  pickModVersion,
  sources,
  ...
}:

with lib;

let
  inherit
    (import ./mkPrismInstance.nix {
      inherit
        lib
        pkgs
        mkModDir
        mkPrismComponentPatch
        mkMmcPackComponent
        ;
    })
    mkPrismInstance
    ;

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

  autoMods = mkModTable "mods";
  autoResourcePacks = mkModTable "resourcepacks";
  autoDatapacks = mkModTable "datapacks";

  # Modrinth-backed modpacks: project -> versionKey -> { package; date; dependencies; }.
  autoModpacks = mapAttrs (
    project: entry:
    mapAttrs (_versionKey: v: {
      package = mkModrinthPackTree {
        inherit project;
        versionRecord = v;
      };
      inherit (v) date dependencies;
    }) entry.versions
  ) (filterAttrs (_: e: e.type == "modrinth-modpack") (minecraftSources.modpacks or { }));

  # Shared submodule type for mods/resourcePacks/datapacks -- one
  # project -> versionKey -> resolved-package-plus-metadata table.
  modVersionsTableType = types.attrsOf (
    types.attrsOf (
      types.submodule {
        options = {
          package = mkOption { type = types.package; };
          gameVersions = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          loaders = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          date = mkOption {
            type = types.str;
            default = "";
          };
        };
      }
    )
  );

  # prism-component registry entries, keyed by uid (one entry per component,
  # each holding every tracked version -- sources.toml registers just the
  # bare uid, e.g. "net.minecraft", not a specific version).
  componentsByUid = listToAttrs (
    map (e: nameValuePair e.uid e) (
      attrValues (filterAttrs (_: e: e.type == "prism-component") (minecraftSources.libraries or { }))
    )
  );
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
  loaderDependencyKeyToBareName = {
    forge = "forge";
    "fabric-loader" = "fabric";
    "quilt-loader" = "quilt";
    neoforge = "neoforge";
  };
  loaderUidByKey = {
    forge = "net.minecraftforge";
    fabric = "net.fabricmc.fabric-loader";
    quilt = "org.quiltmc.quilt-loader";
    neoforge = "net.neoforged";
  };
  loaderFromDependencies =
    deps:
    let
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
        mods = extraMods;
        resourcePacks = extraResourcePacks;
        datapacks = extraDatapacks;
        inherit (g) configs files;
      };
    };

  # Computed once; both resolvedInstances (per-instance deployment/Steam) and
  # the shared libraries/ cache below (deduped across every instance) read
  # from this same table instead of re-running resolveGame twice.
  resolved = mapAttrs resolveGame config.games.minecraft.games;
  resolvedInstances = mapAttrs (_: r: r.instance) resolved;

  # Every library (+ mainJar) needed by any registered instance, deduped by
  # its Maven path -- same jar at the same path is identical content
  # regardless of which instance pulled it in, so last-one-wins collapsing
  # via listToAttrs is exactly the union we want. Placed in PrismLauncher's
  # shared libraries/ cache, not per-instance, matching how PrismLauncher
  # itself organizes them.
  sharedLibraries = listToAttrs (
    map (l: nameValuePair l.path l.drv) (
      concatMap mkPrismComponentLibraries (concatMap (r: r.components) (attrValues resolved))
    )
  );

in
{
  imports = [ ./poc.nix ];

  options.games.minecraft = {
    mods = mkOption {
      type = modVersionsTableType;
      default = { };
      description = "project -> versionKey -> resolved mod package + compatibility metadata, auto-populated from sources.nix's [modrinth] entries.";
    };
    resourcePacks = mkOption {
      type = modVersionsTableType;
      default = { };
      description = "Same shape as mods, for resource packs.";
    };
    datapacks = mkOption {
      type = modVersionsTableType;
      default = { };
      description = "Same shape as mods, for datapacks.";
    };

    modpacks = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        Either a Modrinth-backed modpack's versions table (project ->
        versionKey -> { package; date; dependencies; }, auto-populated from
        sources.nix's [modrinth-modpack] entries), or a hand-defined custom
        modpack: { minecraftVersion; loader; mods = { name = "latest" |
        versionKey; }; resourcePacks = {...}; datapacks = {...}; }.
      '';
    };

    games = mkOption {
      default = { };
      description = ''
        Instance definitions. The only registry that becomes a Steam
        shortcut. Set only `modpack` to run it exactly as published; add
        `mods`/`resourcePacks`/`datapacks`/`configs`/`files` to layer
        extras on top; omit `modpack` entirely for a fully custom instance
        (`minecraftVersion`/`loader`/`loaderVersion` are then required).
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            modpack = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            modpackVersion = mkOption {
              type = types.str;
              default = "latest";
            };
            minecraftVersion = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            loader = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            loaderVersion = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            mods = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
            resourcePacks = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
            datapacks = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
            configs = mkOption {
              type = types.attrsOf types.path;
              default = { };
            };
            files = mkOption {
              type = types.attrsOf types.path;
              default = { };
            };
          };
        }
      );
    };
  };

  config = {
    # Auto-population: a plain config contribution, not `default`, so
    # hand-written entries elsewhere still merge in via normal attrsOf
    # semantics.
    games.minecraft.mods = autoMods;
    games.minecraft.resourcePacks = autoResourcePacks;
    games.minecraft.datapacks = autoDatapacks;
    games.minecraft.modpacks = autoModpacks;

    programs.steam.games = mapAttrs' (
      name: _instanceDrv:
      nameValuePair name {
        inherit name;
        game = name;
        launcher = {
          package = pkgs.prismlauncher;
          args = [ "-l" ];
        };
        workingDirectory = "${dirs.hmConfig}/PrismLauncher/instances/${name}";
      }
    ) resolvedInstances;

    xdg.dataFile =
      foldlAttrs (
        acc: name: instanceDrv:
        acc
        // {
          "PrismLauncher/instances/${name}/instance.cfg".source = "${instanceDrv}/instance.cfg";
          "PrismLauncher/instances/${name}/mmc-pack.json".source = "${instanceDrv}/mmc-pack.json";
          "PrismLauncher/instances/${name}/patches".source = "${instanceDrv}/patches";
          "PrismLauncher/instances/${name}/.minecraft/mods".source = "${instanceDrv}/.minecraft/mods";
          "PrismLauncher/instances/${name}/.minecraft/resourcepacks".source =
            "${instanceDrv}/.minecraft/resourcepacks";
          "PrismLauncher/instances/${name}/.minecraft/datapacks".source =
            "${instanceDrv}/.minecraft/datapacks";
          "PrismLauncher/instances/${name}/.minecraft/config".source = "${instanceDrv}/.minecraft/config";
          "PrismLauncher/instances/${name}/.minecraft/saves".source =
            mkOutOfStoreSymlink "${dirs.hmConfig}/PrismLauncher/instances/${name}/.minecraft/saves";
          "PrismLauncher/instances/${name}/.minecraft/logs".source =
            mkOutOfStoreSymlink "${dirs.hmConfig}/PrismLauncher/instances/${name}/.minecraft/logs";
          "PrismLauncher/instances/${name}/.minecraft/options.txt".source =
            mkOutOfStoreSymlink "${dirs.hmConfig}/PrismLauncher/instances/${name}/.minecraft/options.txt";
        }
      ) { } resolvedInstances
      // mapAttrs' (
        path: drv: nameValuePair "PrismLauncher/libraries/${path}" { source = drv; }
      ) sharedLibraries;
  };
}
