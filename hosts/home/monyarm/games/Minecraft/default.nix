{
  lib,
  pkgs,
  config,
  dirs,
  mkOutOfStoreSymlink,
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
      attrValues (
        filterAttrs (_: e: e.type == "prism-component" && e ? versions) (minecraftSources.libraries or { })
      )
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
            resourcePackOrder = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = ''
                Overrides the modpack's own resourcePacks:[...] list
                (first entry = top of the in-game list = highest priority).
                A home-manager
                activation script patches just that one line of the real
                .minecraft/options.txt on every switch (creating the file
                if absent), leaving every other setting the game itself
                wrote untouched -- null leaves resourcePacks alone
                entirely, letting the game/modpack manage it normally.
              '';
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
        acc: name: r:
        let
          inst = r.instance;
          base = "PrismLauncher/instances/${name}";
          fileEntries =
            subdir: fs:
            listToAttrs (
              map (f: nameValuePair "${base}/.minecraft/${subdir}/${f.name}" { source = f.path; }) fs
            );
        in
        acc
        // {
          "${base}/instance.cfg".source = "${inst.instanceBase}/instance.cfg";
          "${base}/mmc-pack.json".source = "${inst.instanceBase}/mmc-pack.json";
          "${base}/patches".source = "${inst.instanceBase}/patches";
          "${base}/.minecraft/config".source =
            mkOutOfStoreSymlink "${dirs.hmConfig}/${base}/.minecraft/config";
          "${base}/.minecraft/saves".source = mkOutOfStoreSymlink "${dirs.hmConfig}/${base}/.minecraft/saves";
          "${base}/.minecraft/logs".source = mkOutOfStoreSymlink "${dirs.hmConfig}/${base}/.minecraft/logs";
          "${base}/.minecraft/options.txt".source =
            mkOutOfStoreSymlink "${dirs.hmConfig}/${base}/.minecraft/options.txt";
        }
        // fileEntries "mods" inst.modFiles
        // fileEntries "resourcepacks" inst.resourcePackFiles
        // fileEntries "datapacks" inst.datapackFiles
        // listToAttrs (
          map (f: nameValuePair "${base}/.minecraft/${f.path}" { inherit (f) source; }) inst.extraSymlinkFiles
        )
      ) { } resolved
      // mapAttrs' (
        path: drv: nameValuePair "PrismLauncher/libraries/${path}" { source = drv; }
      ) sharedLibraries;

    home.activation.minecraftMutableContent = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        # config/ reconciliation: reseed a file only if it's unmodified
        # since the last deploy (tracked via a per-file hash sidecar);
        # never clobber an edited file -- write the new version alongside
        # as <file>.nix-new and warn instead. ponytail: whole-file hash
        # granularity, not a real 3-way content merge -- upgrade only if
        # .nix-new conflicts turn out to be frequent in practice.
        reseedFn = ''
          nix_minecraft_reseed_config() {
            local seed="$1" destf="$2" statefile="$3"
            mkdir -p "$(dirname "$destf")" "$(dirname "$statefile")"
            local newhash
            newhash="$(sha256sum "$seed" | cut -d' ' -f1)"
            if [ ! -e "$destf" ]; then
              cp "$seed" "$destf"; chmod u+w "$destf"
              echo "$newhash" > "$statefile"
              return 0
            fi
            local curhash lasthash
            curhash="$(sha256sum "$destf" | cut -d' ' -f1)"
            lasthash=""
            [ -f "$statefile" ] && lasthash="$(cat "$statefile")"
            if [ "$curhash" = "$newhash" ]; then
              echo "$newhash" > "$statefile"
            elif [ "$curhash" = "$lasthash" ]; then
              cp "$seed" "$destf"; chmod u+w "$destf"
              echo "$newhash" > "$statefile"
            else
              cp "$seed" "$destf.nix-new"
              echo "minecraft: $destf changed locally and in the nix config -- wrote new version to $destf.nix-new, merge by hand." >&2
            fi
          }
        '';
        perGame =
          name: r:
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              relPath: seed:
              let
                instanceDir = "${dirs.hmConfig}/PrismLauncher/instances/${name}";
              in
              ''nix_minecraft_reseed_config "${seed}" "${instanceDir}/.minecraft/config/${relPath}" "${instanceDir}/.nix-seed-state/config/${relPath}.sha256"''
            ) r.instance.mutableConfigFiles
          );
      in
      ''
        ${reseedFn}
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList perGame resolved)}
      ''
    );

    home.activation.minecraftOptionsTxt = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        patchFn = ''
          nix_minecraft_patch_line() {
            local file="$1" pattern="$2" newline="$3"
            mkdir -p "$(dirname "$file")"
            if [ ! -e "$file" ]; then
              printf '%s\n' "$newline" > "$file"
              return 0
            fi
            local matches
            matches="$(grep -c -E "$pattern" "$file" || true)"
            if [ "$matches" -eq 0 ]; then
              printf '%s\n' "$newline" >> "$file"
            elif [ "$matches" -eq 1 ]; then
              local tmp
              tmp="$(mktemp)"
              NIX_MC_NEWLINE="$newline" awk -v pat="$pattern" '
                $0 ~ pat { print ENVIRON["NIX_MC_NEWLINE"]; next }
                { print }
              ' "$file" > "$tmp"
              mv "$tmp" "$file"
            else
              echo "minecraft: $file has $matches lines matching /$pattern/ -- expected 0 or 1, refusing to guess which to patch. Resolve by hand, then re-run switch." >&2
              return 1
            fi
          }
        '';
        perGame =
          name: r:
          lib.optionalString (r.resourcePackOrder != null) ''
            nix_minecraft_patch_line \
              "${dirs.hmConfig}/PrismLauncher/instances/${name}/.minecraft/options.txt" \
              '^resourcePacks:' \
              'resourcePacks:${builtins.toJSON r.resourcePackOrder}' || exit 1
          '';
      in
      ''
        ${patchFn}
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList perGame resolved)}
      ''
    );
  };
}
