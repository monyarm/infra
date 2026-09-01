{
  config,
  lib,
  fetchSteam,
  marchiveUnpack,
  marchiveUnpack',
  ...
}:
{
  config = lib.mkIf config.games.emulation.enable {
    games.emulation.marchive = {
      contra =
        fetchSteam {
          filelist = [
            "windata/alldata.bin"
            "windata/alldata.psb.m"
          ];
          appId = 1018020;
          depotId = 1018021;
          manifestId = 6443479726234578030;
          sha256 = "sha256-qNeuZTnsddh36ZTH0VS6YdSoeb3BlCW7Hd/mZEy7oSQ=";
        }
        |> marchiveUnpack "contra";

      castlevaniaAnniversary =
        fetchSteam {
          filelist = [
            "windata/alldata.bin"
            "windata/alldata.psb.m"
          ];
          appId = 1018010;
          depotId = 1018011;
          manifestId = 4125351698578021580;
          sha256 = "sha256-REhFKIssc3IfLjR6sAZXaYDXvP6tz69wuPq545B0+fc=";
        }
        |> marchiveUnpack' "castlevania-anniversary" [ "073/script/title_standalone.nut" ];

      castlevaniaAdvance =
        fetchSteam {
          filelist = [
            "windata/alldata.bin"
            "windata/alldata.psb.m"
          ];
          appId = 1552550;
          depotId = 1552551;
          manifestId = 8609910394922333285;
          sha256 = "sha256-tK/e8Ch266UTWzGfoWsDksMKlgVZaO0zB07KDpvQsds=";
        }
        |> marchiveUnpack "castlevania-advance";
    };

    programs.steam.games = {
      CONTRA_ANNIVERSARY_COLLECTION_SOURCE = {
        disabled = true;
        name = "Contra Anniversary Collection";
        steamAppId = 1018020;
      };
      CASTLEVANIA_ANNIVERSARY_COLLECTION_SOURCE = {
        disabled = true;
        name = "Castlevania Anniversary Collection";
        steamAppId = 1018010;
      };
      CASTLEVANIA_ADVANCE_COLLECTION_SOURCE = {
        disabled = true;
        name = "Castlevania Advance Collection";
        steamAppId = 1552550;
      };
    };
  };
}
