{
  config,
  lib,
  ripDiscContents,
  compressScummvmGame,
  getFiles,
  ...
}:
let
  theDig =
    ripDiscContents {
      name = "The Dig (USA)";
      sha256 = "sha256-PNQPfmT7WOfpDQywfuxFqwtdjHsvKQ6PTDBHF3/gEwo=";
    }
    |> getFiles [
      "DIG/DIG.LA0"
      "DIG/DIG.LA1"
      "DIG/DIGMUSIC.BUN"
      "DIG/DIGVOICE.BUN"
      "DIG/BIGFONT.NUT"
      "DIG/SMLFONT.NUT"
      "DIG/VIDEO/*.SAN"
      "DIG/VIDEO/*.TRS"
      "DIG/VIDEO/*.NUT"
    ]
    |> compressScummvmGame "scumm";

  theFullThrottle =
    ripDiscContents {
      name = "Full Throttle";
      sha256 = "sha256-x4Fnc72U2xdDLSMJxy0vL9lEPmMqLAU1stYD/e+3nYI=";
    }
    |> getFiles [
      "Resource/FT.LA0"
      "Resource/FT.LA1"
      "Resource/MONSTER.SOU"
      "Resource/TITLFNT.NUT"
      "Resource/BRUSH.NUT"
      "Resource/LEC.TRS"
      "Resource/DATA/*.SAN"
      "Resource/DATA/*.TRS"
      "Resource/DATA/*.NUT"
      "Resource/DATA/*.FLU"
      "Resource/DATA/*.RIP"
      "Resource/VIDEO/*.SAN"
      "Resource/VIDEO/*.TRS"
    ]
    |> compressScummvmGame "scumm";

  theSamAndMax =
    ripDiscContents {
      name = "Sam and Max Hit the Road";
      sha256 = "sha256-k7BaOaIVV7X/HoFBOeB3BYK4r2MgaZZPk7QmZFZPBaE=";
    }
    |> getFiles [
      "SAMNMAX/SAMNMAX.000"
      "SAMNMAX/SAMNMAX.001"
      "SAMNMAX/MONSTER.SOU"
    ]
    |> compressScummvmGame "scumm";
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games = {
    dig = {
      gameid = "dig";
      engineid = "scumm";
      guioptions = "sndNoMIDI";
      description = "The Dig";
      path = "${theDig}/DIG";
    };
    ft = {
      gameid = "ft";
      engineid = "scumm";
      extra = "Version A";
      guioptions = "sndNoMIDI";
      description = "Full Throttle";
      path = "${theFullThrottle}/Resource";
    };
    samnmax = {
      gameid = "samnmax";
      engineid = "scumm";
      extra = "CD";
      enable_enhancements = true;
      guioptions = "gameOption2";
      description = "Sam & Max Hit the Road";
      path = "${theSamAndMax}/SAMNMAX";
    };
  };
}
