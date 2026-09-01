{
  lib,
  pkgs,
  compressRom',
  ...
}:
let
  # single place to swap a system's emulator
  systemLaunchers = {
    nes = pkgs.mesen;
    snes = pkgs.snes9x-gtk;
    gb = pkgs.mgba;
    gbc = pkgs.mgba;
    gba = pkgs.mgba;
    genesis = pkgs.blastem;
    gamegear = pkgs.gearsystem;
  };

  # Sibling keys consumed by compressRom, never format-identifying -- stripped
  # from the game config so they don't leak into programs.steam.games options.
  auxKeys = [
    "patch"
    "sidecar"
    "tracks"
  ];

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
    in
    romArgs
    // {
      game = compressRom' parent ({ inherit rom; } // compressArgs);
      launcher = {
        package = systemLaunchers.${system};
      }
      // launcher;
    };
in
{
  inherit mkRom;
}
