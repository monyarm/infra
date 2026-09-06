{
  lib,
  pkgs,
  compressRom',
  addChecks,
  # Optional: unused when a caller (e.g. tests) overrides systemEmulators
  # with its own fixture instead of the real emulators.nix.
  mkSmoke ? null,
  systemEmulators ? import ./emulators.nix { inherit pkgs mkSmoke; },
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

  # No `rom` passed to these -- they default to reading addChecks' own
  # $out (see emulators.nix's romRef), so checks validate the real,
  # single-built artifact instead of a separately-built reference to it.
  buildBaseChecks =
    {
      emulator,
      system,
      patch,
    }:
    let
      patchScript = systemEmulators.patchCommand { inherit patch; };
      patchCheck = if patch == null then { } else { patch = patchScript; };
      structureCheck = {
        structure = emulator.structure { inherit system; };
      };
      smokeCheck = lib.optionalAttrs (emulator.smoke != null) { inherit (emulator) smoke; };
    in
    structureCheck // patchCheck // smokeCheck;

  buildCompressedChecks =
    { emulator }:
    # compressedSmoke defaults to smoke; a system sets it to null to skip
    # the post-compression smoke check specifically (e.g. NES/Mesen's
    # --testrunner can't load a compressed archive at all).
    let
      compressedSmoke = emulator.compressedSmoke or emulator.smoke;
    in
    if compressedSmoke == null then { } else { smoke = compressedSmoke; };

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
        inherit emulator system;
        patch = selectPatch args;
      };
      checkedRom = addChecks baseChecks rom;

      # Compression receives the checked ROM and still gets the original patch args.
      compressed = compressRom' parent ({ rom = checkedRom; } // compressArgs);

      # Post-compression smoke runs against the exact compressed artifact.
      compressedChecks = buildCompressedChecks { inherit emulator; };
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
