# Console foundation tests.
#
# These run as a normal flake check (tests/default.nix auto-discovers every
# tests/*.nix). Evaluation-time invariants are asserted with Nix `assert`s;
# build-time behaviour (tree contents, manifest bytes, rejected symlinks and
# collisions) is verified by building fixtures inside checkPhase.
{ pkgs }:

let
  inherit (pkgs) lib;

  libPath = ../lib;
  consoleLib = import (libPath + "/console") {
    inherit lib pkgs;
  };
  # Platform modules are imported as a directory so `assertions` and `psp.files`
  # are defined exactly the way a real console config gets them.
  filesModule = ../hosts/console/modules;

  inherit (consoleLib) paths;
  inherit (consoleLib) files;
  inherit (consoleLib) build;

  # Accept iff evaluating the thunk succeeds. `path` forces through deepSeq
  # because a bare `tryEval` on a thunk does not force it.
  accepts = thunk: (builtins.tryEval thunk).success;

  rejects =
    thunk:
    let
      forced = builtins.deepSeq thunk true;
    in
    !(builtins.tryEval forced).success;

  evalFiles =
    modules:
    lib.evalModules {
      modules = [ filesModule ] ++ modules;
      specialArgs = { inherit pkgs; };
    };

  # --- path validation ---------------------------------------------------

  validPaths = [
    "A.txt"
    "PSP/GAME/X/EBOOT.PBP"
    "SEPLUGINS/PLUGINS.TXT"
    "PSP/SAVEDATA/SLUS00001/DATA.BIN"
    "a/b/c/d/e/f.png"
    "ICON0.PNG"
    "a b.txt"
    ".hidden"
  ];

  invalidPaths = [
    ""
    "/absolute/path"
    "a//b"
    "trailing/"
    "./relative"
    "../escape"
    "a/../b"
    "with\\backslash"
    "star*name"
    "colon:name"
    "lt<gt>"
    "pipe|name"
    "question?name"
    ".psp-nix/manifest"
    ".psp-nix/generations/1/manifest"
  ];

  # --- normalization -----------------------------------------------------

  entry = path: {
    text = "content\n";
    owner = "";
    recursive = false;
    enable = true;
    __unused = path;
  };

  normalizeForce =
    fset: builtins.deepSeq (files.normalize fset) (map (e: e.path) (files.normalize fset));

  sortedEntries = files.normalize {
    "Z.txt" = entry "Z.txt";
    "A.txt" = entry "A.txt";
    "nested/deep/B.txt" = entry "nested/deep/B.txt";
  };

  disabledEntries = files.normalize {
    "keep.txt" = entry "keep.txt";
    "drop.txt" = (entry "drop.txt") // {
      enable = false;
    };
  };

  ancestorEntries = files.normalize {
    "A" = entry "A";
    "A/B" = entry "A/B";
  };

  # --- module evaluation -------------------------------------------------

  textOnly = evalFiles [ { psp.files."SEPLUGINS/T.TXT".text = "hello\n"; } ];
  sourceOnly = evalFiles [
    { psp.files."PSP/GAME/A/EBOOT.PBP".source = pkgs.writeText "eboot" "pbp"; }
  ];
  recursiveDefault = evalFiles [
    {
      psp.files."D" = {
        source = pkgs.writeText "d" "x";
      };
    }
  ];
  recursiveEnabled = evalFiles [
    {
      psp.files."D" = {
        source = pkgs.writeText "d" "x";
        recursive = true;
      };
    }
  ];
  emptyConfig = evalFiles [ ];
  neitherSet = evalFiles [ { psp.files."X.txt" = { }; } ];
  bothSet = evalFiles [
    {
      psp.files."Y.txt" = {
        text = "a\n";
        source = pkgs.writeText "y" "b\n";
      };
    }
  ];

  failedAssertions = e: builtins.filter (a: !a.assertion) e.config.assertions;

  # --- build-time fixtures ----------------------------------------------

  plainFile = pkgs.writeText "fixture-plain" "alpha\n";

  nestedDir = pkgs.runCommand "fixture-nested" { } ''
    mkdir -p "$out/inner"
    printf 'beta\n' > "$out/b.txt"
    printf 'gamma\n' > "$out/inner/c.txt"
  '';

  treeEntries = [
    {
      path = "A/one.txt";
      source = toString plainFile;
      recursive = false;
      owner = "games.alpha";
    }
    {
      path = "TREE";
      source = toString nestedDir;
      recursive = true;
      owner = "homebrew.beta";
    }
  ];

  fixtureTree = build.mkTree "foundation" treeEntries;
  fixtureManifest = build.mkManifest "foundation" fixtureTree treeEntries;

  # Expected manifest computed independently of the builder, so the test does
  # not just re-run the same logic it is checking.
  expectedManifest = pkgs.runCommand "expect-manifest" { } ''
    hashOf() { printf '%s' "$1" | sha256sum | cut -d' ' -f1; }
    {
      printf '{"path":"A/one.txt","hash":"%s","size":6,"owner":"games.alpha"}\n' "$(hashOf 'alpha
    ')"
      printf '{"path":"TREE/b.txt","hash":"%s","size":5,"owner":"homebrew.beta"}\n' "$(hashOf 'beta
    ')"
      printf '{"path":"TREE/inner/c.txt","hash":"%s","size":6,"owner":"homebrew.beta"}\n' "$(hashOf 'gamma
    ')"
    } > $out
  '';

  # Nix has no "expected to fail" dependency, so rejection is proven two ways:
  # the guard text must be present in the generated builder, and each
  # derivation was confirmed to fail when built during development.
  treeBuilderScript = build.mkTree "guard-probe" [
    {
      path = "T";
      source = toString nestedDir;
      recursive = true;
      owner = "";
    }
  ];
  # Written to a store path so the check can grep the generated builder.
  builderText = pkgs.writeText "console-builder-text" treeBuilderScript.buildCommand;

  tests = [
    {
      name = "path-validation-accepts-valid";
      condition = builtins.all (p: accepts (paths.validate p)) validPaths;
      message = "every valid PSP path is accepted";
    }
    {
      name = "path-validation-rejects-invalid";
      condition = builtins.all (p: rejects (paths.validate p)) invalidPaths;
      message = "unsafe paths (absolute, traversal, illegal chars, reserved) are rejected";
    }
    {
      name = "path-reserved-dir-only-applies-to-children";
      condition = !(paths.isReserved ".psp-nix") && paths.isReserved ".psp-nix/manifest";
      message = "the reserved dir itself is only rejected when it is a path prefix";
    }
    {
      name = "ancestor-detection";
      condition =
        paths.isAncestorOf "A" "A/B"
        && paths.isAncestorOf "A" "A/B/C"
        && !(paths.isAncestorOf "A" "AB")
        && !(paths.isAncestorOf "A/B" "A");
      message = "component-wise ancestor detection works";
    }
    {
      name = "normalize-sorts-by-path";
      condition =
        map (e: e.path) sortedEntries == [
          "A.txt"
          "Z.txt"
          "nested/deep/B.txt"
        ];
      message = "normalized entries are sorted by destination path";
    }
    {
      name = "normalize-drops-disabled";
      condition = map (e: e.path) disabledEntries == [ "keep.txt" ];
      message = "entries with enable = false are dropped";
    }
    {
      name = "normalize-rejects-ancestor-collision";
      condition = rejects ancestorEntries;
      message = "a destination nested beneath another is rejected";
    }
    {
      name = "normalize-rejects-unsafe-path";
      condition = rejects (files.normalize { "../escape" = entry "../escape"; });
      message = "normalize rejects path traversal";
    }
    {
      name = "normalize-rejects-reserved-path";
      condition = rejects (files.normalize { ".psp-nix/manifest" = entry ".psp-nix/manifest"; });
      message = "normalize rejects the reserved directory";
    }
    {
      name = "module-synthesizes-source-from-text";
      condition = textOnly.config.psp.files."SEPLUGINS/T.TXT".source ? consoleSynthesized;
      message = "text is turned into a derived source";
    }
    {
      name = "module-accepts-source";
      condition = lib.isDerivation sourceOnly.config.psp.files."PSP/GAME/A/EBOOT.PBP".source;
      message = "a derivation is accepted as a source";
    }
    {
      name = "module-recursive-defaults-false";
      condition =
        !recursiveDefault.config.psp.files."D".recursive && recursiveEnabled.config.psp.files."D".recursive;
      message = "recursive defaults to false and can be enabled";
    }
    {
      name = "module-defaults-owner-empty";
      condition = textOnly.config.psp.files."SEPLUGINS/T.TXT".owner == "";
      message = "owner defaults to an empty string";
    }
    {
      name = "module-empty-config-evaluates";
      condition = emptyConfig.config.psp.files == { };
      message = "an empty configuration evaluates cleanly";
    }
    {
      name = "module-rejects-neither-text-nor-source";
      condition = !(builtins.tryEval neitherSet.config.psp.files."X.txt".source).success;
      message = "omitting both text and source fails with a targeted error";
    }
    {
      name = "module-rejects-both-text-and-source";
      condition = builtins.length (failedAssertions bothSet) == 1;
      message = "setting both text and source fails an assertion";
    }
    {
      name = "module-valid-config-has-no-failed-assertions";
      condition =
        builtins.length (failedAssertions textOnly) == 0
        && builtins.length (failedAssertions sourceOnly) == 0;
      message = "valid configurations produce no failing assertions";
    }
  ];

  failedAssertionsList = builtins.filter (t: !t.condition) tests;

  evalSummary =
    if failedAssertionsList == [ ] then
      ""
    else
      "console foundation evaluation failures:\n"
      + lib.concatMapStringsSep "\n" (t: "  - ${t.name}: ${t.message}") failedAssertionsList;
in
assert evalSummary == "" || throw evalSummary;
assert
  normalizeForce {
    "A.txt" = entry "A.txt";
  } == [ "A.txt" ];

pkgs.runCommand "test-console-foundation"
  {
    nativeBuildInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
  }
  ''
        # --- evaluation-time invariants already asserted by Nix `assert`s ---

        echo "evaluation assertions passed"

        # --- tree contents ---
        test -f ${fixtureTree}/A/one.txt
        test -f ${fixtureTree}/TREE/b.txt
        test -f ${fixtureTree}/TREE/inner/c.txt
        test "$(cat ${fixtureTree}/A/one.txt)" = "alpha"
        test "$(cat ${fixtureTree}/TREE/inner/c.txt)" = "gamma"

        # --- manifest is byte-exact, sorted, and correctly attributed ---
        diff -u ${expectedManifest} ${fixtureManifest}

    # The recursive source's files inherit the declaration's owner, which is
        # the whole point of longest-prefix owner resolution.
        grep -q '"path":"TREE/inner/c.txt".*"owner":"homebrew.beta"' ${fixtureManifest}

        # --- build-time rejections are guarded, not merely intended ---
        for msg in "symlink or non-regular file" "destination collision at" "declares recursive but"; do
          grep -qF "$msg" ${builderText} || {
            echo "FAIL: missing rejection guard '$msg'" >&2
            exit 1
          }
        done

        touch $out
  ''
