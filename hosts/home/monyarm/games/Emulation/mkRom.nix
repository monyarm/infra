{
  lib,
  pkgs,
  compressRom,
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
  };

  # generalizes Doom's mkDoom; rom always goes through real compressRom
  mkRom =
    {
      rom,
      system,
      launcher ? { },
      ...
    }@args:
    (lib.removeAttrs args [
      "rom"
      "system"
      "launcher"
    ])
    // {
      game = compressRom rom;
      launcher = {
        package = systemLaunchers.${system};
      }
      // launcher;
    };
in
{
  inherit mkRom;
}
