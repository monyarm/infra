{
  config,
  lib,
  pkgs,
  getFile,
  fetchIdGames,
  fetchModDB,
  fetchGDrive,
  mkDoom,
  sources,
  ...
}:
let
  # Master Levels Rejects -- 15 WADs for the 1995 Master Levels that didn't
  # make the cut. Feed WadFusion's source_wads; not standalone game entries.

  # doomshack.org is unreachable over https; fetch from a Wayback Machine
  # capture instead (its own http redirect points here anyway).
  mlRejectCaballZip = pkgs.fetchzip {
    url = "https://web.archive.org/web/20250925130036/https://doomshack.org/uploads/caball.zip";
    hash = "sha256-2onlwuhz18YkqI5hrzNjuGaB3mh4vuUMjX8kAvBpX3s=";
    stripRoot = false;
  };

  # WizardWorks-era retail add-ons, publisher defunct since 2004, no rights-
  # reversion found (unlike Perdition's Gate) -- archive.org as an
  # unlicensed-source stopgap, replace if a legit rip turns up. Each zip is
  # a full DOS install; only the add-on's own WAD is used below.
  hell2payZip = pkgs.fetchzip {
    url = "https://archive.org/download/msdos_Hell_to_Pay_1996/Hell_to_Pay_1996.zip";
    hash = "sha256-cB9hBSSotdt6CY/HzdRpO9/o5ipO5bI116Tomye+nss=";
    stripRoot = false;
  };
  lostEpisodesZip = pkgs.fetchzip {
    url = "https://archive.org/download/msdos_The_Lost_Episodes_of_Doom_1995/The_Lost_Episodes_of_Doom_1995.zip";
    hash = "sha256-Ik3/uBtTNOKe9vEoU0jSGMtQsaThwtkBiY+H3RCoPdw=";
    stripRoot = false;
  };

  # Varied Doom v4 -- weapon/monster/pickup randomizer, per-category toggles
  # in its own options menu (used weapons-only here; monsters already
  # covered by anotherMonsterRandomizer below). forum.zdoom.org's live
  # attachment download is Anubis-gated; pre-Anubis Wayback capture instead
  # (same play as mlRejectCaball above).
  variedDoomZip = pkgs.fetchzip {
    url = "http://web.archive.org/web/20230421112245if_/https://forum.zdoom.org/download/file.php?id=39225";
    hash = "sha256-MhWMchRYpBDyiTVOFM3D9lbDwyl/SPavDjC/CALRdV0=";
    stripRoot = false;
    extension = "zip";
  };

  # WadFusion v1.6.1 -- plain-Python release, omgifol (as `omg/`) vendored
  # inside the zip, no separate dependency needed.
  wadfusionSrc = pkgs.fetchzip {
    url = "https://github.com/Owlet7/wadfusion/releases/download/v1.6.1/wadfusion_py.zip";
    hash = "sha256-oL9GJz3/lGWN9SC+2IcTd2149sDOQyUypFsX9V1/Pc4=";
    stripRoot = false;
  };

  # Every source name WadFusion v1.6.1 recognizes (its own WADS/REPORT_WADS
  # lists) -- looks for "<name>.wad" case-insensitively in the `-w`
  # directory. Only doom/doom2 are required here; WadFusion itself degrades
  # gracefully on anything else missing (logs and skips).
  mkWadFusion =
    inputs:
    let
      required = [
        "doom"
        "doom2"
      ];
      missingRequired = lib.filter (n: (inputs.${n} or null) == null) required;
      sourceWads = pkgs.linkFarm "wadfusion-source-wads" (
        lib.mapAttrsToList (name: drv: {
          name = "${name}.wad";
          path = drv;
        }) (lib.filterAttrs (_: v: v != null) inputs)
      );
    in
    assert lib.assertMsg (
      missingRequired == [ ]
    ) "mkWadFusion: missing required input(s): ${toString missingRequired}";
    pkgs.stdenvNoCC.mkDerivation {
      name = "doom_fusion.ipk3";
      dontUnpack = true;
      nativeBuildInputs = [ pkgs.python3 ];
      buildPhase = ''
        runHook preBuild
        cp -r ${wadfusionSrc} wadfusion
        chmod -R u+w wadfusion
        # Redirect (not pipe) answers WadFusion's two Y/N prompts --
        # `yes | ...` can trip stdenv's pipefail on SIGPIPE.
        (cd wadfusion && python3 wadfusion.py -w ${sourceWads} <<< $'Y\nY\n')
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        cp wadfusion/doom_fusion.ipk3 $out
        runHook postInstall
      '';
    };
in
lib.mkIf config.games.doom.enable (
  with config.games.doom;
  # `wadfusion` deliberately isn't a `games.doom.wads.*` entry: that
  # option's `attrsOf` merge forces every sibling's value just to check
  # definedness, so an entry reading `config.games.doom.wads.<x>` is real
  # infinite recursion (hit this, not hypothetical). Read siblings from a
  # different option instead (`programs.steam.games`, same as doom_i_ii.nix).
  let
    wadfusion = mkWadFusion {
      inherit (wads)
        doom
        doom2
        tnt
        plutonia
        nerve
        sigil
        sigil2
        id1
        iddm1
        extras
        sewers
        betray
        e1m4b
        e1m8b
        ;
      masterlevels = wads.masterLevels;
      cpu = wads.mlRejectCpu;
      device_1 = wads.mlRejectDevice1;
      dmz = wads.mlRejectDmz;
      cdk_fury = wads.mlRejectCdkFury;
      e_inside = wads.mlRejectEInside;
      hive = wads.mlRejectHive;
      twm01 = wads.mlRejectTwm01;
      mines = wads.mlRejectMines;
      anomaly = wads.mlRejectAnomaly;
      farside = wads.mlRejectFarside;
      trouble = wads.mlRejectTrouble;
      dante25 = wads.mlRejectDante25;
      achron22 = wads.mlRejectAchron22;
      udtwid = wads.mlRejectUdtwid;
      caball = wads.mlRejectCaball;
      # Unity/KEX widescreen bonus variants -- not owned. Explicit null (not
      # omitted) so this shows exactly what's missing at a glance.
      doomu = null;
      doomunity = null;
      doom2unity = null;
      tntunity = null;
      plutoniaunity = null;
      doomkex = null;
      doom2kex = null;
      tntkex = null;
      plutoniakex = null;
      # Sigil/Sigil II Buckethead/THORR soundtrack upgrades -- paid
      # (EUR6.66 each, romero.com/shop), not owned. WadFusion resolves
      # these by scanning candidate filenames; using each list's primary
      # name as the placeholder key.
      sigil_shreds = null;
      sigil2_mp3 = null;
    };

    # Phase 4: extract each map-pool source's maps into its own prefixed
    # maps/*.wad files (name/prefix derived from filename by
    # build_custom_maps.py -- adding a source is just adding its path).
    # Composite sources (below) are for mods whose maps and actor-defining
    # scripts live in separate files -- doomednum range and where the
    # resolving script lives matter, not own-IWAD-vs-PWAD.
    customMapsManifest = pkgs.writeText "wadfusion-custom-maps-manifest.json" (
      builtins.toJSON {
        omgPath = "${wadfusionSrc}";
        baseIpk3 = "${wadfusion}";
        outputDir = "out";
        # Freedoom reuses vanilla doomednums by design; its only real
        # conflict is texture names colliding with real Doom's.
        renameAssets = [
          "freedoom1"
          "freedoom2"
        ];
        sources =
          map (d: "${d}") (
            with wads;
            [
              tntr
              pl2
              prcp
              neis
              jpcp
              doomZero
              tnt2Devilution
              perditionsGate
              hell2pay
              jptrV40
              freedoom1
              freedoom2
            ]
          )
          ++ [
            # sam01's Things use doomednums 22005-29476 (vanilla tops out
            # ~3006) -- genuinely custom actors, checked directly.
            # build_custom_maps.py auto-discovers what they need (DECORATE's
            # own #include list, loose files/dirs) but excludes the resource
            # wad's own MAPINFO/SBARINFO/KEYCONF -- not GZDoom "cumulative"
            # types, would clobber WadFusion's global setup.
            {
              name = "sam01";
              container = "${wads.seriousSamRetroEncounter}";
              # Campaign spans 5 nested wads, not just sam01.wad -- checked
              # each with omg, not assumed from the filename.
              maps = [
                "sam01.wad"
                "seg01.wad"
                "seg02.wad"
                "Seg03.wad"
                "INT01.wad"
              ];
              resourceWads = [ "RetroEncounter-Resources.wad" ];
            }
          ];
      }
    );
    customMaps = pkgs.stdenvNoCC.mkDerivation {
      name = "custom_maps.pk3";
      dontUnpack = true;
      nativeBuildInputs = [
        pkgs.python3
        pkgs.zip
      ];
      buildPhase = ''
        runHook preBuild
        mkdir out
        python3 ${./build_custom_maps.py} ${customMapsManifest}
        # ZScript entry points are matched by base name ("zscript"),
        # extension-agnostic, same as WadFusion's own "zscript.zs" -- this
        # is a separate pk3, so it needs its own independent entry point;
        # ZSCRIPT is cumulative across loaded files, same as DECORATE.
        cp ${./roguelike_shuffle.zs} out/zscript.zs
        (cd out && zip -qr ../custom_maps.pk3 .)
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        cp custom_maps.pk3 $out
        runHook postInstall
      '';
    };
  in
  {
    games.doom.wads = {
      mlRejectCpu = fetchIdGames sources.wad.mlRejectCpu |> getFile "cpu.wad";
      mlRejectDevice1 = fetchIdGames sources.wad.mlRejectDevice1 |> getFile "device_1.wad";
      mlRejectDmz = fetchIdGames sources.wad.mlRejectDmz |> getFile "dmz.wad";
      mlRejectCdkFury = fetchIdGames sources.wad.mlRejectCdkFury |> getFile "cdk_fury.wad";
      mlRejectEInside = fetchIdGames sources.wad.mlRejectEInside |> getFile "e_inside.wad";
      mlRejectHive = fetchIdGames sources.wad.mlRejectHive |> getFile "hive.wad";
      mlRejectTwm01 = fetchIdGames sources.wad.mlRejectTwm01 |> getFile "TWM01.WAD";
      mlRejectMines = fetchIdGames sources.wad.mlRejectMines |> getFile "MINES.WAD";
      mlRejectAnomaly = fetchIdGames sources.wad.mlRejectAnomaly |> getFile "anomaly.wad";
      mlRejectFarside = fetchIdGames sources.wad.mlRejectFarside |> getFile "FARSIDE.WAD";
      mlRejectTrouble = fetchIdGames sources.wad.mlRejectTrouble |> getFile "TROUBLE.WAD";
      mlRejectDante25 = fetchIdGames sources.wad.mlRejectDante25 |> getFile "DANTE25.WAD";
      mlRejectAchron22 = fetchIdGames sources.wad.mlRejectAchron22 |> getFile "ACHRON22.WAD";
      mlRejectCaball = mlRejectCaballZip |> getFile "CABALL.WAD";
      mlRejectUdtwid = fetchIdGames sources.wad.mlRejectUdtwid |> getFile "UDTWiD.wad";

      # Map-shuffle-pool community megawads (feed build_dynamic.py, not WadFusion's
      # own source_wads -- see the roguelike-stack plan doc's Phase 3).
      tntr = fetchIdGames sources.wad.tntr |> getFile "TNTR.wad";
      pl2 = fetchIdGames sources.wad.pl2 |> getFile "PL2.WAD";
      prcp = fetchIdGames sources.wad.prcp |> getFile "PRCP.wad";
      neis = fetchIdGames sources.wad.neis |> getFile "NEIS.wad";
      # Deliberately skip the zip's JPCP_HUD.wad (Katakana/Kanji status bar
      # replacement) -- not wanted, per the plan doc.
      jpcp = fetchIdGames sources.wad.jpcp |> getFile "JPCP.wad";
      doomZero = fetchModDB sources.wad.doomZero |> getFile "DOOM_ZERO_ver3/DoomZero.wad";
      # v1.2 final; supersedes the beta6-via-Dropbox target now that a
      # current release exists on idgames (see sources.toml).
      tnt2Devilution = fetchIdGames sources.wad.tnt2Devilution |> getFile "TNT2_1_2.wad";
      # Rights reverted to the original creators in 2016 -- legitimately
      # freeware, unlike Hell to Pay/Lost Episodes below.
      perditionsGate = fetchIdGames sources.wad.perditionsGate |> getFile "Pdgate.wad";
      hell2pay = hell2payZip |> getFile "HelltoPa/DOOM2/HELL2PAY.WAD";
      jptrV40 = lostEpisodesZip |> getFile "TheLostE/DOOM/JPTR_V40.WAD";
      # Romero's Blackroom warm-up remakes -- add new E1M4B/E1M8B map lumps,
      # don't replace E1M4/E1M8 (confirmed by reading wadfusion.py).
      e1m8b = fetchIdGames sources.wad.e1m8b |> getFile "e1m8b.wad";
      e1m4b = fetchIdGames sources.wad.e1m4b |> getFile "e1m4b.wad";

      # Phase 5: gameplay mutators layered on top of the finished IWAD+maps.
      # MOShuffle/Vandomizer/Universal Entropy dropped -- see the roguelike
      # plan doc: MOShuffle's map discovery can't handle a multi-prefix pool
      # (replaced by roguelike_shuffle.zs above), Vandomizer/Universal
      # Entropy only substitute among vanilla-Doom actor classes, blind to
      # anything sam01/CorruptionCards adds.
      # Actor-pool-agnostic (any loaded monster class, vanilla or modded,
      # joins the replacement pool) -- zdoom forum OP links a Google Drive
      # file directly, not a forum attachment, so no Anubis gate.
      anotherMonsterRandomizer = fetchGDrive sources.wad.anotherMonsterRandomizer;
      corruptionCards = fetchModDB sources.wad.corruptionCards |> getFile "CorruptionCards-v6.3b.pk3";
      # Weapon/monster/pickup randomizer with per-category toggles in its
      # own options menu -- only its weapon-randomization toggle should be
      # enabled in-game (monsters already covered by anotherMonsterRandomizer
      # above; enabling both would double-randomize monsters).
      variedDoom = variedDoomZip |> getFile "VariedDoomV4.pk3";
    };

    programs.steam.games = {
      WADFUSION_ROGUELIKE = mkDoom {
        name = "DOOM Fusion: Roguelike";
        iwad = wadfusion;
        wad = [
          # Bundled super-ultra-widescreen assets (Ultra-Widerpix854 project) --
          # per WadFusion's own README, loads automatically when sitting next
          # to the IPK3. Same already-fetched release zip, just a second member.
          (wadfusionSrc |> getFile "doom_fusion_widescreen_gfx.pk3")
          customMaps
          wads.anotherMonsterRandomizer
          wads.corruptionCards
          wads.variedDoom
        ];
        images = {
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/52699fa80061960bdd1064367a7f47e0.jpg";
            sha256 = "sha256-mY0e2lbgZD5cDekoVXY/VqTKg9Udn/IwLmSqdAWH1Sw=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/131efc3e9dc6088e07ffe4a4c0b2997d.png";
            sha256 = "sha256-PBRfMLxYvUSxObyvs0vsZ8g3TKb48++pa9ZBuXTxXX4=";
          };
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/c98399cf427813fcbe9bd5ad68d18f56.png";
            sha256 = "sha256-nz4/nx197ggJTM2pcalMHi9/vHGWCXwLQlxLFYSOZ9w=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/c2341621cac5449c2e3b8b6a653b3f12.jpg";
            sha256 = "sha256-NG3tZai6KGlt8mawfUtVsi7xZfhuICOOFKle+ttjnFE=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/9373a1d0e8a2225fd83ce8d97fd59ac2.png";
            sha256 = "sha256-6+D/X7r/lX2TjptUzH0wpMKChYf/iencgiS9Jy3hviE=";
          };
        };
      };
    };
  }
)
