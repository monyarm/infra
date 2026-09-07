{
  lib,
  pkgs,
  mkModDir,
  mkPrismComponentPatch,
  mkMmcPackComponent,
  ...
}:
{
  # Builds one instance's pieces. Nothing here is deployed as a whole-folder
  # symlink -- the caller (default.nix) decides per piece:
  #   - instanceBase (instance.cfg/mmc-pack.json/patches): declarative-only,
  #     symlinked whole.
  #   - modFiles/resourcePackFiles/datapackFiles: file-level, one xdg.dataFile
  #     symlink per jar, so a mod/launcher can freely add its own files into
  #     the same real directory without fighting a symlinked folder.
  #   - mutableSeed (everything else the modpack ships -- config/,
  #     defaultconfigs/, kubejs/, configureddefaults/, ...): activation-time
  #     COPIED, never symlinked, since mods rewrite their own config files
  #     at runtime. The caller hash-tracks each seeded file so a later
  #     `switch` only reseeds files the player/a mod hasn't touched since.
  #   - filesSeed (the `files` arg, instance-root paths): same
  #     activation-copy treatment, rooted one level up from mutableSeed.
  mkPrismInstance =
    {
      name,
      minecraftComponent, # resolved prism-component record for net.minecraft
      loaderComponent ? null, # resolved prism-component record for the loader, or null
      modpackTree ? null, # built modpack directory (its whole .minecraft/-relative content), or null
      modpackFiles ? [ ], # the modpack's own modrinth.index.json files[], each already fetched: [{ path; drv; }]
      mods ? [ ], # extra mod packages -- each package's own name/pname becomes its filename
      resourcePacks ? [ ],
      datapacks ? [ ],
      configs ? { }, # "file.toml" -> path, placed under .minecraft/config, activation-copied
      files ? { }, # "relative/instance/path" -> path, placed at the instance root, activation-copied
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

      # File-level entries for the three binary-content dirs: the modpack's
      # own files[] entries under that prefix (already individually fetched
      # with their own hash) plus any explicitly-listed extra packages.
      modpackFilesUnder = prefix: builtins.filter (f: lib.hasPrefix prefix f.path) modpackFiles;
      namedFileList =
        prefix: extra:
        (map (f: {
          name = builtins.baseNameOf f.path;
          path = f.drv;
        }) (modpackFilesUnder prefix))
        ++ (map (p: {
          name = p.name or p.pname;
          path = p;
        }) extra);

      modFiles = namedFileList "mods/" mods;
      resourcePackFiles = namedFileList "resourcepacks/" resourcePacks;
      datapackFiles = namedFileList "datapacks/" datapacks;

      # Everything the modpack ships besides mods/resourcepacks/datapacks
      # (those are handled above as file-level entries instead), plus
      # explicit configs. Rooted at .minecraft/.
      mutableSeed = pkgs.runCommand "${name}-mutable-seed" { } ''
        mkdir -p "$out"
        ${lib.optionalString (modpackTree != null) ''
          cp -rT "${modpackTree}" "$out"
          rm -rf "$out/mods" "$out/resourcepacks" "$out/datapacks"
        ''}
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (relPath: src: ''
            mkdir -p "$out/config/$(dirname "${relPath}")"
            cp -r "${src}" "$out/config/${relPath}"
          '') configs
        )}
      '';

      filesSeed = pkgs.runCommand "${name}-files-seed" { } ''
        mkdir -p "$out"
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (relPath: src: ''
            mkdir -p "$out/$(dirname "${relPath}")"
            cp -r "${src}" "$out/${relPath}"
          '') files
        )}
      '';
    in
    {
      inherit
        instanceBase
        modFiles
        resourcePackFiles
        datapackFiles
        mutableSeed
        filesSeed
        ;
    };
}
