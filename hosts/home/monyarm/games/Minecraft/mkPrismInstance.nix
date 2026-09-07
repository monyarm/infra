{
  lib,
  pkgs,
  mkModDir,
  mkPrismComponentPatch,
  mkMmcPackComponent,
  ...
}:
{
  # Builds one instance's store-backed tree:
  #   instance.cfg, mmc-pack.json, patches/*.json,
  #   .minecraft/{mods,resourcepacks,datapacks,config}
  # Runtime-mutated paths (saves/, logs/, options.txt) are NOT part of this
  # output -- the caller wires those as mkOutOfStoreSymlink targets instead.
  # Never references Steam -- that mapping lives in default.nix only.
  mkPrismInstance =
    {
      name,
      minecraftComponent, # resolved prism-component record for net.minecraft
      loaderComponent ? null, # resolved prism-component record for the loader, or null
      modpackTree ? null, # a built modpack directory (mods/resourcepacks/datapacks/overrides), or null
      mods ? [ ], # extra mod packages layered on top -- each package's own name/pname becomes its filename
      resourcePacks ? [ ],
      datapacks ? [ ],
      configs ? { }, # "file.toml" -> path, placed under .minecraft/config
      files ? { }, # "relative/instance/path" -> path, placed at the instance root
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

      # Places a plain path->source attrset at exact (possibly nested)
      # relative paths -- for configs/files, where names come from user-given
      # keys rather than a package's own name.
      placeAt =
        drvName: pathMap:
        pkgs.runCommand drvName { } ''
          mkdir -p "$out"
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (relPath: src: ''
              mkdir -p "$out/$(dirname "${relPath}")"
              cp -r "${src}" "$out/${relPath}"
            '') pathMap
          )}
        '';

      # Places a list of packages at their own name/pname -- for
      # mods/resourcePacks/datapacks, where the filename IS the identity
      # (e.g. sodium-fabric-0.5.8.jar).
      namedPackagesLayer =
        drvName: packages:
        pkgs.linkFarm drvName (
          map (p: {
            name = p.name or p.pname;
            path = p;
          }) packages
        );

      subdirTree =
        subdir: modpackSub: explicitList:
        mkModDir {
          name = "${name}-${subdir}";
          layers = lib.optional (modpackTree != null) "${modpackTree}/${modpackSub}" ++ [
            (namedPackagesLayer "${name}-${subdir}-explicit" explicitList)
          ];
        };

      modsTree = subdirTree "mods" "mods" mods;
      resourcePacksTree = subdirTree "resourcepacks" "resourcepacks" resourcePacks;
      datapacksTree = subdirTree "datapacks" "datapacks" datapacks;

      configTree = mkModDir {
        name = "${name}-config";
        layers = lib.optional (modpackTree != null) "${modpackTree}/config" ++ [
          (placeAt "${name}-config-explicit" configs)
        ];
      };

      filesTree = placeAt "${name}-files-explicit" files;

      baseTree = pkgs.runCommand "${name}-base" { } ''
        mkdir -p "$out"
        cat > "$out/instance.cfg" <<'CFGEOF'
        ${instanceCfg}
        CFGEOF
        cat > "$out/mmc-pack.json" <<'PACKEOF'
        ${mmcPack}
        PACKEOF
        mkdir -p "$out/patches" "$out/.minecraft/mods" "$out/.minecraft/resourcepacks" "$out/.minecraft/datapacks" "$out/.minecraft/config"
        cp -rT "${patchesDir}" "$out/patches"
        cp -rT "${modsTree}" "$out/.minecraft/mods"
        cp -rT "${resourcePacksTree}" "$out/.minecraft/resourcepacks"
        cp -rT "${datapacksTree}" "$out/.minecraft/datapacks"
        cp -rT "${configTree}" "$out/.minecraft/config"
      '';
    in
    mkModDir {
      inherit name;
      layers = [
        baseTree
        filesTree
      ];
    };
}
