{
  lib,
  pkgs,
  mkPrismComponentPatch,
  mkMmcPackComponent,
  ...
}:
{
  # Builds one instance's pieces. Nothing here is a whole-folder symlink to
  # the store -- the caller (default.nix) deploys each piece differently:
  #   - instanceBase (instance.cfg/mmc-pack.json/patches): declarative-only,
  #     symlinked whole.
  #   - modFiles/resourcePackFiles/datapackFiles/extraSymlinkFiles:
  #     file-level store symlinks -- static content nothing rewrites at
  #     runtime, so Nix stays authoritative and a modpack update or
  #     nix-config change just changes what's symlinked. No reconciliation
  #     needed for any of these.
  #   - mutableConfigFiles: config/ specifically -- mods rewrite their own
  #     config files at runtime, so these need real writable files. The
  #     caller hash-tracks each one to reseed only what's unmodified since
  #     the last deploy.
  #   - filesSeed: the `files` arg (instance-root paths), copy-once.
  mkPrismInstance =
    {
      name,
      minecraftComponent, # resolved prism-component record for net.minecraft
      loaderComponent ? null, # resolved prism-component record for the loader, or null
      modpackTree ? null, # built modpack directory (its .minecraft/-relative content), or null
      modpackFiles ? [ ], # the modpack's own modrinth.index.json files[], each already fetched: [{ path; drv; }]
      overridesFiles ? [ ], # every path bundled under the modpack's overrides/, relative to it
      mods ? [ ], # extra mod packages -- each package's own name/pname becomes its filename
      resourcePacks ? [ ],
      datapacks ? [ ],
      configs ? { }, # "relpath-under-config" -> path, wins over the modpack's own config/<relpath>
      files ? { }, # "relative/instance/path" -> path, placed at the instance root, copy-once
    }:
    let
      components = [ minecraftComponent ] ++ lib.optional (loaderComponent != null) loaderComponent;

      instanceCfg = lib.generators.toKeyValue { } {
        InstanceType = "OneSix";
        inherit name;
        iconKey = "default";
      };

      mmcPack = builtins.toJSON {
        formatVersion = 1;
        components = map mkMmcPackComponent components;
      };

      patchesDir = pkgs.runCommand "${name}-patches" { } ''
        mkdir -p "$out"
        ${lib.concatMapStringsSep "\n" (c: ''
          cat > "$out/${c.uid}.json" <<'PATCHEOF'
          ${mkPrismComponentPatch c}
          PATCHEOF
        '') components}
      '';

      instanceBase = pkgs.runCommand "${name}-base" { } ''
        mkdir -p "$out" "$out/patches"
        cat > "$out/instance.cfg" <<'CFGEOF'
        ${instanceCfg}
        CFGEOF
        cat > "$out/mmc-pack.json" <<'PACKEOF'
        ${mmcPack}
        PACKEOF
        cp -rT "${patchesDir}" "$out/patches"
      '';

      isUnder = prefix: path: lib.hasPrefix prefix path;
      overridesUnder = prefix: builtins.filter (isUnder prefix) overridesFiles;

      # File-level entries for the three binary-content dirs: the modpack's
      # own files[] entries under that prefix, plus any of the same content
      # a pack bundled directly in overrides/ instead, plus explicit extras.
      namedFileList =
        prefix: extra:
        (map (f: {
          name = builtins.baseNameOf f.path;
          path = f.drv;
        }) (builtins.filter (f: isUnder prefix f.path) modpackFiles))
        ++ (map (p: {
          name = builtins.baseNameOf p;
          path = "${modpackTree}/${p}";
        }) (overridesUnder prefix))
        ++ (map (p: {
          name = p.name or p.pname;
          path = p;
        }) extra);

      modFiles = namedFileList "mods/" mods;
      resourcePackFiles = namedFileList "resourcepacks/" resourcePacks;
      datapackFiles = namedFileList "datapacks/" datapacks;

      # Everything else the pack ships (kubejs/, defaultconfigs/,
      # configureddefaults/, ...) -- static content nothing rewrites at
      # runtime, so a plain store symlink is always correct and needs no
      # reconciliation.
      claimedPrefixes = [
        "mods/"
        "resourcepacks/"
        "datapacks/"
        "config/"
      ];
      extraSymlinkFiles = map (p: {
        path = p;
        source = "${modpackTree}/${p}";
      }) (builtins.filter (p: !(lib.any (pre: isUnder pre p) claimedPrefixes)) overridesFiles);

      # config/ is the one directory mods actively rewrite at runtime, so it
      # needs real mutable files, not symlinks -- the caller hash-tracks
      # each of these to reconcile modpack updates against in-game edits.
      # Explicit `configs` entries win over the pack's own file at the same
      # relative path.
      configFromPack = lib.listToAttrs (
        map (p: lib.nameValuePair (lib.removePrefix "config/" p) "${modpackTree}/${p}") (
          overridesUnder "config/"
        )
      );
      mutableConfigFiles = configFromPack // configs;
    in
    {
      inherit
        instanceBase
        modFiles
        resourcePackFiles
        datapackFiles
        extraSymlinkFiles
        mutableConfigFiles
        ;
      filesSeed = files;
    };
}
