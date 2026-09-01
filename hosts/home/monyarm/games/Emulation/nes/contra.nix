{
  config,
  lib,
  getFile,
  mkRom,
  ...
}:
let
  inherit (config.games.emulation) marchive;
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    contra = marchive.contra |> getFile "nes_Contra.nes";
    superC = marchive.contra |> getFile "nes_SuperC.nes";

    # regional variants, registered for enumeration only -- not launchable
    probotectorII = marchive.contra |> getFile "nes_ProbotectorII.nes";
    contraFamicom = marchive.contra |> getFile "famicom_Contra.nes";
    superContraFamicom = marchive.contra |> getFile "famicom_SuperContra.nes";
  };

  programs.steam.games = with config.games.emulation.roms; {
    CONTRA = mkRom {
      name = "Contra";
      rom = contra;
      system = "nes";
    };
    SUPER_C = mkRom {
      name = "Super C";
      rom = superC;
      system = "nes";
    };
  };
}
