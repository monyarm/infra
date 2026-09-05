{
  lib,
  pkgs,
  compressRom',
  addChecks,
  systemEmulators ? import ./emulators.nix { inherit pkgs; },
  ...
}:
let
  # Sibling keys consumed by compressRom, never format-identifying -- stripped
  # from the game config so they don't leak into programs.steam.games options.
  auxKeys = [
    "patch"
    "sidecar"
    "tracks"
  ];

  selectPatch =
    args:
    let
      patches = if args ? patch && args.patch != null then args.patch else [ ];
      patches' = if builtins.isList patches then patches else [ patches ];
    in
    lib.findFirst (candidate: candidate != null) null patches';

  buildBaseChecks =
    {
      emulator,
      rom,
      system,
      patch,
    }:
    let
      patchScript = systemEmulators.patchCommand { inherit patch rom; };
      patchCheck = if patch == null then { } else { patch = patchScript; };
      structureCheck = {
        structure = emulator.structure {
          inherit system rom;
        };
      };
      smokeScript = if emulator.smoke == null then null else emulator.smoke { inherit rom; };
      smokeCheck = lib.optionalAttrs (smokeScript != null) { smoke = smokeScript; };
    in
    structureCheck // patchCheck // smokeCheck;

  buildCompressedChecks =
    {
      emulator,
      rom,
    }:
    if emulator.smoke == null then { } else { smoke = emulator.smoke { inherit rom; }; };

  # generalizes Doom's mkDoom; rom always goes through real compressRom
  mkRom =
    {
      rom,
      system,
      launcher ? { },
      parent ? null,
      ...
    }@args:
    let
      # Keep the public game arguments separate from compressor-only inputs.
      romArgs = lib.removeAttrs args (
        [
          "rom"
          "system"
          "launcher"
          "parent"
        ]
        ++ auxKeys
      );
      compressArgs = lib.intersectAttrs (lib.genAttrs auxKeys (_: null)) args;

      # Select the emulator before constructing checks for either artifact.
      emulator = systemEmulators.${system};

      # Base checks run against the original ROM.
      baseChecks = buildBaseChecks {
        inherit emulator rom system;
        patch = selectPatch args;
      };
      checkedRom = addChecks baseChecks rom;

      # Compression receives the checked ROM and still gets the original patch args.
      compressed = compressRom' parent ({ rom = checkedRom; } // compressArgs);

      # Post-compression smoke runs against the exact compressed artifact.
      compressedChecks = buildCompressedChecks {
        inherit emulator;
        rom = compressed;
      };
      checkedGame = addChecks compressedChecks compressed;
    in
    romArgs
    // {
      game = checkedGame;
      launcher = {
        package = emulator.launcher;
      }
      // launcher;
    };
in
{
  inherit mkRom;
}
