# Tests for the launchable-resource model, Categories Lite layout, and ARK-5
# configuration generation.
#
# Evaluation-time invariants (category layout, metadata precedence, assertions)
# are checked with Nix `assert`s. Build-time behaviour (homebrew merging, the
# exact bytes of SETTINGS.TXT / PLUGINS.TXT) is checked by building fixtures.
{ pkgs }:

let
  inherit (pkgs) lib;

  consoleLib = import (../lib/console) {
    inherit lib pkgs;
  };
  resources = import (../lib/console/resources.nix) { inherit lib; };
  modules = ../hosts/console/modules;

  isoA = pkgs.writeText "game-a.iso" "iso-payload-a";
  isoB = pkgs.writeText "game-b.iso" "iso-payload-b";
  icon = pkgs.writeText "icon.png" "png-payload";
  background = pkgs.writeText "background.png" "bg-payload";
  bgm = pkgs.writeText "bgm.at3" "at3-payload";
  homebrewPkg = pkgs.runCommand "homebrew-app" { } ''
    mkdir -p "$out"
    printf 'pbp-payload' > "$out/EBOOT.PBP"
  '';

  evalPsp =
    extra:
    lib.evalModules {
      modules = [ modules ] ++ extra;
      specialArgs = {
        inherit pkgs;
        inherit (consoleLib) plugins;
      };
    };

  failures = e: builtins.filter (a: !a.assertion) e.config.assertions;

  # --- category directory naming ----------------------------------------

  inherit (resources) categoryFolder;

  # --- resource layout ---------------------------------------------------

  plainGames = evalPsp [
    {
      psp.categoriesLite.enable = false;
      psp.games.a = {
        type = "psp-iso";
        source = isoA;
        category = "Puzzle";
      };
    }
  ];

  categorised =
    let
      e = evalPsp [
        {
          psp.categoriesLite = {
            enable = true;
            prefix = true;
          };
          psp.games.puzzle = {
            type = "psp-iso";
            source = isoA;
            category = "Puzzle";
          };
          psp.games.strategy = {
            type = "psp-cso";
            source = isoB;
            category = "Strategy";
          };
        }
      ];
    in
    map (e: e.path) (consoleLib.normalize e.config.psp.files);

  prefixedOff = map (e: e.path) (
    consoleLib.normalize
      (evalPsp [
        {
          psp.categoriesLite = {
            enable = true;
            prefix = false;
          };
          psp.games.puzzle = {
            type = "psp-iso";
            source = isoA;
            category = "Puzzle";
          };
        }
      ]).config.psp.files
  );

  sortedLayout = map (e: e.path) (
    consoleLib.normalize
      (evalPsp [
        {
          psp.categoriesLite = {
            enable = true;
            prefix = true;
            sort = true;
          };
          psp.games.b = {
            type = "psp-iso";
            source = isoA;
            category = "Zeta";
          };
          psp.games.a = {
            type = "psp-iso";
            source = isoB;
            category = "Alpha";
          };
        }
      ]).config.psp.files
  );

  # --- homebrew ----------------------------------------------------------

  homebrewNoAssets = evalPsp [
    {
      psp.categoriesLite.enable = true;
      psp.homebrew.app = {
        package = homebrewPkg;
        category = "Homebrew";
      };
    }
  ];

  homebrewWithAssets =
    let
      e = evalPsp [
        {
          psp.categoriesLite.enable = true;
          psp.homebrew.app = {
            package = homebrewPkg;
            category = "Homebrew";
            metadata = {
              inherit icon;
              inherit background;
              inherit bgm;
            };
          };
        }
      ];
    in
    builtins.head (builtins.attrValues e.config.psp.files);

  # --- metadata precedence ----------------------------------------------

  globalDefaultIcon = pkgs.writeText "glob-icon.png" "glob";
  resourceOverridesGlobal = builtins.head (
    builtins.attrValues
      (evalPsp [
        {
          psp.categoriesLite.enable = true;
          psp.metadata.defaultIcon = globalDefaultIcon;
          psp.homebrew.app = {
            package = homebrewPkg;
            category = "Homebrew";
            metadata.icon = icon;
          };
        }
      ]).config.psp.files
  );

  # The built homebrew tree should contain the resource icon, not the global one.
  resourceIconWins = pkgs.runCommand "check-resource-icon-wins" { } ''
    if grep -q "png-payload" ${resourceOverridesGlobal.source}/ICON0.PNG; then
      touch $out
    else
      echo "expected the resource icon to win over the global default" >&2
      exit 1
    fi
  '';

  # --- metadata on disc images is rejected -------------------------------

  discWithAssets = evalPsp [
    {
      psp.games.bad = {
        type = "psp-iso";
        source = isoA;
        category = "Puzzle";
        metadata.icon = icon;
      };
    }
  ];

  # --- too many categories ----------------------------------------------

  tooManyCategories = evalPsp [
    {
      psp.categoriesLite.enable = true;
      psp.games = builtins.listToAttrs (
        map (n: {
          name = "g${toString n}";
          value = {
            type = "psp-iso";
            source = isoA;
            category = "Cat${toString n}";
          };
        }) (lib.range 1 9)
      );
    }
  ];

  # --- ARK-5 -------------------------------------------------------------

  arkDisabled = evalPsp [
    { psp.cfw.ark5.enable = false; }
  ];

  ark = evalPsp [
    {
      psp.cfw.ark5 = {
        enable = true;
        settings = {
          usbcharge = true;
          noled = false;
          cpuclock = "333";
          mscache = "8k";
        };
      };
      # Plugins now live in the shared `psp.plugins` registry; cwcheat has no
      # pinned download, so it supplies its own binary here.
      psp.plugins = {
        categories-lite.enable = true;
        cwcheat = {
          enable = true;
          source = pkgs.writeText "cwcheat.prx" "fake-prx";
          runlevel = "umd";
        };
      };
    }
  ];

  arkFiles = consoleLib.normalize ark.config.psp.files;
  arkByPath = builtins.listToAttrs (
    map (e: {
      name = e.path;
      value = e;
    }) arkFiles
  );

  arkSettings = pkgs.runCommand "ark-settings" { } ''
    grep -q "always, usbcharge, on" ${arkByPath."PSP/SAVEDATA/ARK_01234/SETTINGS.TXT".source}
    grep -q "always, noled, off" ${arkByPath."PSP/SAVEDATA/ARK_01234/SETTINGS.TXT".source}
    grep -q "always, cpuclock:333, on" ${arkByPath."PSP/SAVEDATA/ARK_01234/SETTINGS.TXT".source}
    grep -q "always, mscache:8k, on" ${arkByPath."PSP/SAVEDATA/ARK_01234/SETTINGS.TXT".source}
    touch $out
  '';

  arkPlugins = pkgs.runCommand "ark-plugins" { } ''
    grep -q "vsh, ms0:/SEPLUGINS/category_lite.prx, on" ${arkByPath."SEPLUGINS/PLUGINS.TXT".source}
    grep -q "umd, ms0:/SEPLUGINS/cwcheat.prx, on" ${arkByPath."SEPLUGINS/PLUGINS.TXT".source}
    touch $out
  '';

  # --- plugin registry behaviour ---------------------------------------

  noPlugins = consoleLib.normalize (evalPsp [ { } ]).config.psp.files;

  onlyCategoryLite =
    consoleLib.normalize
      (evalPsp [
        {
          psp.plugins.categories-lite.enable = true;
        }
      ]).config.psp.files;

  pluginOrder =
    (evalPsp [
      {
        # Enabled out of alphabetical order to prove ordering is by `order`,
        # not by attrset iteration.
        psp.plugins = {
          missyhud.enable = true;
          categories-lite.enable = true;
        };
      }
    ]).config.psp.pluginEntries
    |> map (e: e.name);

  unsourcedPlugin = evalPsp [
    {
      # Registry entry exists but ships no pinned binary.
      psp.plugins.cwcheat.enable = true;
    }
  ];

  # --- tests list --------------------------------------------------------

  tests = [
    {
      name = "category-folder-prefix-on";
      condition =
        categoryFolder {
          category = "Puzzle";
          prefix = true;
        } == "CAT_Puzzle";
      message = "prefix adds CAT_";
    }
    {
      name = "category-folder-prefix-off";
      condition =
        categoryFolder {
          category = "Puzzle";
          prefix = false;
        } == "Puzzle";
      message = "no prefix leaves the bare name";
    }
    {
      name = "category-folder-sort";
      condition =
        categoryFolder {
          category = "Puzzle";
          prefix = true;
          sort = true;
          order = 3;
        } == "CAT_03Puzzle";
      message = "sort numbers the folder after CAT_";
    }
    {
      name = "category-folder-sort-no-prefix";
      condition =
        categoryFolder {
          category = "Puzzle";
          prefix = false;
          sort = true;
          order = 12;
        } == "12Puzzle";
      message = "sort without prefix numbers the folder directly";
    }
    {
      name = "plugin-disabled-no-category-dir";
      condition =
        map (e: e.path) (consoleLib.normalize plainGames.config.psp.files) == [
          "ISO/a.iso"
        ];
      message = "without Categories Lite a game sits at the ISO root";
    }
    {
      name = "plugin-enabled-category-dir";
      condition =
        categorised == [
          "ISO/CAT_Puzzle/puzzle.iso"
          "ISO/CAT_Strategy/strategy.cso"
        ];
      message = "categories place games under their category directory";
    }
    {
      name = "prefix-off-layout";
      condition = prefixedOff == [ "ISO/Puzzle/puzzle.iso" ];
      message = "prefix=false drops CAT_";
    }
    {
      name = "sort-layout";
      condition =
        sortedLayout == [
          "ISO/CAT_00Alpha/a.iso"
          "ISO/CAT_01Zeta/b.iso"
        ];
      message = "sort orders categories deterministically by name";
    }
    {
      name = "homebrew-recursive-entry";
      condition =
        let
          e = builtins.head (builtins.attrValues homebrewNoAssets.config.psp.files);
        in
        e.recursive && e.source != null;
      message = "homebrew is one recursive directory entry";
    }
    {
      name = "homebrew-owner";
      condition =
        (builtins.head (builtins.attrValues homebrewNoAssets.config.psp.files)).owner == "homebrew.app";
      message = "homebrew entries carry their resource owner";
    }
    {
      name = "homebrew-asset-entry";
      condition = homebrewWithAssets.recursive;
      message = "homebrew with assets is still a single recursive entry";
    }
    {
      name = "disc-with-assets-rejected";
      condition = builtins.length (failures discWithAssets) == 1;
      message = "declaring metadata assets on an ISO is an error";
    }
    {
      name = "too-many-categories-rejected";
      condition = builtins.any (a: !a.assertion) tooManyCategories.config.assertions;
      message = "more than 8 categories fails an assertion";
    }
    {
      name = "ark-disabled-writes-nothing";
      condition = consoleLib.normalize arkDisabled.config.psp.files == [ ];
      message = "with ARK-5 disabled no config files are generated";
    }
    {
      name = "ark-settings-owner";
      condition = arkByPath."PSP/SAVEDATA/ARK_01234/SETTINGS.TXT".owner == "cfw.ark5";
      message = "ARK-5 files are attributed to the cfw owner";
    }
    {
      name = "no-plugins-by-default";
      condition = noPlugins == [ ];
      message = "no plugin files are generated unless one is enabled";
    }
    {
      name = "registry-plugin-enables-alone";
      condition = map (e: e.path) onlyCategoryLite == [ "SEPLUGINS/category_lite.prx" ];
      message = "a registry plugin needs only enable = true";
    }
    {
      name = "plugin-owner-attribution";
      condition = (builtins.head onlyCategoryLite).owner == "plugins.categories-lite";
      message = "plugin files carry their plugin owner";
    }
    {
      name = "categories-lite-sorts-first";
      condition =
        pluginOrder == [
          "categories-lite"
          "missyhud"
        ];
      message = "Categories Lite loads before other VSH plugins regardless of declaration order";
    }
    {
      name = "unsourced-plugin-rejected";
      condition = builtins.any (a: !a.assertion) unsourcedPlugin.config.assertions;
      message = "enabling a registry plugin with no pinned binary fails an assertion";
    }
    {
      name = "ark-plugins-owner";
      condition = arkByPath."SEPLUGINS/PLUGINS.TXT".owner == "cfw.ark5";
      message = "PLUGINS.TXT is attributed to the cfw owner";
    }
  ];

  failedTests = builtins.filter (t: !t.condition) tests;

  evalSummary =
    if failedTests == [ ] then
      ""
    else
      "console resources evaluation failures:\n"
      + lib.concatMapStringsSep "\n" (t: "  - ${t.name}: ${t.message}") failedTests;
in
assert evalSummary == "" || throw evalSummary;

pkgs.runCommand "test-console-resources" { } ''
  # Each of these is a derivation that fails if its assertion does not hold.
  # Referencing them adds the dependency, which forces the corresponding build.
  for check in \
    ${resourceIconWins} \
    ${arkSettings} \
    ${arkPlugins}
  do
    test -e "$check"
  done
  touch $out
''
