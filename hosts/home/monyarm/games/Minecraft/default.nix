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

  inherit (import ./mkRandomobs.nix { inherit lib pkgs; })
    mkRandomobs
    ;

  inherit
    (import ./registries.nix {
      inherit
        lib
        pkgs
        fetchModrinth
        mkModrinthPackTree
        sources
        ;
    })
    autoMods
    autoResourcePacks
    autoDatapacks
    autoModpacks
    getComponent
    loaderUidByKey
    loaderFromDependencies
    pickLatestByDate
    ;

  inherit
    (import ./resolve.nix {
      inherit
        lib
        config
        mkPrismInstance
        pickModVersion
        pickLatestByDate
        autoMods
        autoResourcePacks
        autoDatapacks
        autoModpacks
        getComponent
        loaderUidByKey
        loaderFromDependencies
        ;
    })
    resolveGame
    ;

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

  deployConfig = import ./deploy.nix {
    inherit
      lib
      pkgs
      dirs
      mkOutOfStoreSymlink
      resolved
      resolvedInstances
      sharedLibraries
      ;
  };
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.games.minecraft.enable (
    deployConfig
    // {
      # Auto-population: a plain config contribution, not `default`, so
      # hand-written entries elsewhere still merge in via normal attrsOf
      # semantics.
      games.minecraft.mods = autoMods;
      games.minecraft.datapacks = autoDatapacks;
      games.minecraft.modpacks = autoModpacks;

      # autoResourcePacks plus a hand-built randomobs pack, registered like
      # any other resource pack -- a bare package (no versions to track or
      # select among, so no versionKey/gameVersions/loaders/date wrapper)
      # rather than inlined at the games.<name>.resourcePacks call site, so
      # it's addressable/reusable the same way a Modrinth-backed pack is.
      games.minecraft.resourcePacks = autoResourcePacks // {
        randomobs = mkRandomobs {
          name = "randomobs";
          packFormat = 15; # 1.20.1
          texturePacks = [ ];
          jarTextures = { };
          skins = {
            zombie = [ ];
          };
        };
      };

      games.minecraft.games = {
        # Modrinth-backed, used as-is (modpackVersion defaults to "latest"),
        # plus the randomobs pack registered above.
        society-sunlit-valley = {
          modpack = "society-sunlit-valley";
          resourcePacks = with config.games.minecraft.resourcePacks; [ randomobs ];
        };
      };
    }
  );
}
