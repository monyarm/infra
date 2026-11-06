{
  lib,
  pkgs,
  config,
  compressRom,
  addChecks,
  autoImport,
  mkSmoke,
  ...
}:
let
  # Every MAME-family libretro core nixpkgs packages -- selected via
  # mkArcade's `emulator` argument when a romset only matches an older
  # MAME driver revision (e.g. a chip-label rename, or a newer required
  # BIOS dependency the dump predates). "mame" itself is deliberately not
  # in this table: that string means standalone pkgs.mame, so there's no
  # ambiguity with the libretro "mame" core of the same name.
  retroarchCores = {
    mame2000 = pkgs.libretro.mame2000;
    mame2003 = pkgs.libretro.mame2003;
    "mame2003-plus" = pkgs.libretro."mame2003-plus";
    mame2010 = pkgs.libretro.mame2010;
    mame2015 = pkgs.libretro.mame2015;
    mame2016 = pkgs.libretro.mame2016;
    fbneo = pkgs.libretro.fbneo;
  };

  # Each libretro core ships a ready-made `bin/retroarch-<core>` wrapper
  # (`exec retroarch -L <core>.so "$@"`), so this never hardcodes the
  # internal .so path. Like standalone MAME, these cores derive the
  # system/driver name from the content file's *basename* -- "$out"'s real
  # CA-hashed filename doesn't match any driver, so content has to be a
  # symlink named "<romName>.zip" first (confirmed empirically: pointing a
  # core directly at "$out" fails with "Game not found: <hash>-<romName>").
  # No CLI flag exists for a null video/audio driver -- an --appendconfig
  # ini does it instead. LIBRETRO_SYSTEM_DIRECTORY is where a core looks for
  # shared BIOS-style dependencies (MAME's -rompath equivalent) -- empty
  # here since no retroarch-based title needs one yet.
  # Libretro MAME cores look for a game's required BIOS/parent zips (e.g.
  # neogeo.zip) alongside the content zip itself, not via a separate
  # rompath list -- so extraRomPaths gets symlinked into the same
  # testRomDir as the content, unlike standalone MAME's -rompath.
  mkRetroarch =
    core: romName: extraRomPaths: overrides:
    let
      corePkg = retroarchCores.${core} or (throw "mkRetroarch: unknown core '${core}'");
      nullDriverConfig = builtins.toFile "retroarch-null.cfg" ''
        video_driver = "null"
        audio_driver = "null"
        input_driver = "null"
        gamemode_enable = "false"
        ui_companion_enable = "false"
        ui_companion_start_on_boot = "false"
      '';
    in
    mkSmoke (
      {
        name = core;
        timeoutSeconds = 30;
        preSetup = ''
          testRomDir="$TMPDIR/${romName}-rompath"
          mkdir -p "$testRomDir" "$TMPDIR/${core}-system"
          ln -s "$out" "$testRomDir/${romName}.zip"
          ${lib.concatMapStringsSep "\n" (p: ''
            for f in "${p}"/*.zip; do
              ln -s "$f" "$testRomDir/$(basename "$f")"
            done
          '') extraRomPaths}
        '';
        command = ''
          ${pkgs.coreutils}/bin/env LIBRETRO_SYSTEM_DIRECTORY="$TMPDIR/${core}-system" QT_QPA_PLATFORM=offscreen \
            ${corePkg}/bin/retroarch-${core} \
            --appendconfig ${nullDriverConfig} \
            --max-frames 300 \
            --verbose \
            "$testRomDir/${romName}.zip"
        '';
        passMessage = "ran 300 frames without crashing";
        failMessage = "${core} exited with status $status";
      }
      // overrides
    );

  # stages the recompressed romset zip into its own rompath dir under the
  # shortname MAME expects
  mkArcade =
    {
      romset,
      shortname,
      extraRomPaths ? [ ],
      # "mame" (default): standalone pkgs.mame, today's behavior. Any other
      # string: a key into retroarchCores, for romsets that only match an
      # older MAME driver revision.
      emulator ? "mame",
      # extra CLI args for standalone MAME (e.g. `-bios us` to select a
      # non-default BIOS alternate); ignored for the retroarch branch.
      mameArgs ? [ ],
      ...
    }@args:
    let
      compressedRomset = compressRom romset;
      # MAME (standalone and every libretro core tested) only resolves a
      # game's parent/BIOS zip (e.g. neogeo.zip) if it sits in the *same*
      # rompath directory as the game's own zip -- confirmed empirically:
      # splitting them across two -rompath entries fails regardless of
      # order, even though each zip individually has correct content.
      mergeExtraRomZips =
        dir:
        lib.concatMapStringsSep "\n" (p: ''
          for f in "${toString p}"/*.zip; do
            ln -s "$f" "${dir}/$(basename "$f")"
          done
        '') extraRomPaths;
      checkedRomset = addChecks {
        smoke =
          if emulator == "mame" then
            mkSmoke {
              name = "mame";
              # -bench counts emulated seconds; under builder load a slow
              # driver needs well over 10 real seconds for -bench 10.
              timeoutSeconds = 120;
              preSetup = ''
                testRomDir="$TMPDIR/${shortname}-rompath"
                mkdir -p "$testRomDir"
                ln -s "$out" "$testRomDir/${shortname}.zip"
                ${mergeExtraRomZips "$testRomDir"}
              '';
              command = ''
                ${pkgs.coreutils}/bin/env SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
                  ${pkgs.mame}/bin/mame \
                  -rompath "$testRomDir" \
                  -video none \
                  -sound none \
                  ${lib.concatMapStringsSep " " lib.escapeShellArg mameArgs} \
                  -bench 10 \
                  ${lib.escapeShellArg shortname}'';
              passMessage = "MAME benchmark completed";
              failMessage = "MAME benchmark failed";
            }
          else
            mkRetroarch emulator shortname extraRomPaths { };
      } compressedRomset;
      romDir =
        pkgs.runCommand "${shortname}-romdir"
          {
            __contentAddressed = true;
            allowSubstitutes = false;
            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
          }
          ''
            mkdir -p $out
            ln -s ${checkedRomset} $out/${shortname}.zip
            ${mergeExtraRomZips "$out"}
          '';
      rompath = "${romDir}";
    in
    (lib.removeAttrs args [
      "romset"
      "shortname"
      "extraRomPaths"
      "emulator"
      "mameArgs"
    ])
    // {
      game = shortname;
      launcher =
        if emulator == "mame" then
          {
            package = pkgs.mame;
            args = [
              "-rompath"
              rompath
            ]
            ++ mameArgs;
          }
        else
          let
            corePkg = retroarchCores.${emulator} or (throw "mkArcade: unknown emulator '${emulator}'");
          in
          {
            # mainProgram override: the core sets none, so resolveExe would
            # guess the pname ("libretro-${emulator}") instead of the real
            # "retroarch-${emulator}" binary it ships.
            package = corePkg // {
              meta = corePkg.meta // {
                mainProgram = "retroarch-${emulator}";
              };
            };
            args = [ "${romDir}/${shortname}.zip" ];
          };
    };

  # every NeoGeo MVS title needs the shared neogeo.zip BIOS on its rompath.
  # Our shared neogeo.zip only carries the "us" bios alternate (sp-u2.sp1),
  # not MAME's default (sp-s2.sp1), so standalone MAME needs -bios us
  # selected explicitly or it fatal-errors -- overridable via mameArgs.
  mkNeoGeo =
    args:
    mkArcade (
      args
      // {
        extraRomPaths =
          (args.extraRomPaths or [ ])
          ++ (lib.optional (config.games.emulation.bios ? neogeo) "${config.games.emulation.bios.neogeo}");
        mameArgs =
          args.mameArgs or (
            if (args.emulator or "mame") == "mame" then
              [
                "-bios"
                "us"
              ]
            else
              [ ]
          );
      }
    );
in
{
  options.games.emulation.bios = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = "Extracted shared BIOS dirs, keyed by system name (e.g. neogeo), populated by the owning system's module.";
  };

  imports = autoImport ./.;

  config = {
    _module.args = { inherit mkArcade mkNeoGeo; };
  };
}
