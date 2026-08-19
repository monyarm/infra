{
  config,
  lib,
  fetchItch,
  sources,
  compressScummvmGame,
  getFiles,
  ...
}:
let
  # Each itch archive ships other platforms'/other-purpose siblings alongside
  # the folder ScummVM actually reads; narrow to that folder before
  # compressScummvmGame walks the tree, instead of after.
  aboveTheWaves =
    fetchItch sources.scummvm.abovethewaves
    |> getFiles [ "AboveTheWaves/data" ]
    |> compressScummvmGame "sludge";
  heroinesQuest =
    fetchItch sources.scummvm.heroinesquest
    |> getFiles [
      "data/Heroine's Quest.ags"
      "data/*.tra"
    ]
    |> compressScummvmGame "ags";
  indianaRodent = fetchItch sources.scummvm.indianarodent |> compressScummvmGame "ags";
  shoaly =
    fetchItch sources.scummvm.shoaly
    |> getFiles [ "Linux/data/SYCBS.ags" ]
    |> compressScummvmGame "ags";
  cosmosQuest3 = fetchItch sources.scummvm.cosmosquest3 |> compressScummvmGame "ags";
  cosmosQuest4 = fetchItch sources.scummvm.cosmosquest4 |> compressScummvmGame "ags";
  aDateInThePark =
    fetchItch sources.scummvm.adateinthepark
    |> getFiles [ "A Date in the Park" ]
    |> compressScummvmGame "ags";
  leewardEp1 =
    fetchItch sources.scummvm.leewardep1
    |> getFiles [ "Leeward Episode 1" ]
    |> compressScummvmGame "ags";
  # itch's only non-demo upload is a plain "Suli FH*.rar" alongside a
  # "DEMO - ..." one with the same "default" upload type/traits, so the
  # sources.toml/update-sources.py pipeline (which has no fileMatch concept)
  # can't disambiguate them; fetch this one directly instead.
  suliFallenHarmony =
    fetchItch {
      url = "https://coutalgames.itch.io/suli-fallen-harmony";
      fileMatch = "Suli FH*.rar";
      platform = "windows";
      hash = "sha256-4FNl0TNeZLeHyQj/3+HRur/uB9qrX2ClYNy9aR9Bggg=";
    }
    |> getFiles [ "Suli FH1.4" ]
    |> compressScummvmGame "ags";
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games = {
    aboveTheWaves = {
      gameid = "atw";
      engineid = "sludge";
      description = "Above The Waves";
      # The detection table (engines/sludge/detection_tables.h) registers this
      # target with no platform (Common::kPlatformUnknown), so leave the
      # bracketed platform tag off rather than defaulting to the misleading
      # "DOS" label.
      platform = "";
      path = "${aboveTheWaves}/AboveTheWaves/data";
    };

    heroinesQuest = {
      gameid = "heroinesquest";
      engineid = "ags";
      description = "Heroine's Quest: The Herald of Ragnarok";
      platform = "";
      path = "${heroinesQuest}/data";
      steamAppId = 283880;
      steamCdnImagesHash = "sha256-L8ijWyeoQZpYgouhb6yWWNznpcsGgRMoJ8BPCvTEA+w=";
    };

    indianaRodent = {
      gameid = "indianarodent";
      engineid = "ags";
      description = "Indiana Rodent: Raiders of the Lost Cheese";
      platform = "";
      # Pre-AGS3 game: the data is appended directly to the .exe, so the
      # fetched root (no data/ subdir) is the detection path.
      path = "${indianaRodent}";
    };

    shoaly = {
      gameid = "shoaly";
      engineid = "ags";
      description = "Shoaly You Can't Be Serious!";
      platform = "";
      path = "${shoaly}/Linux/data";
    };

    cosmosQuest3 = {
      gameid = "cosmosquest3";
      engineid = "ags";
      description = "Cosmos Quest III";
      platform = "";
      path = "${cosmosQuest3}";
    };

    cosmosQuest4 = {
      gameid = "cosmosquest4";
      engineid = "ags";
      description = "Cosmos Quest IV";
      platform = "";
      path = "${cosmosQuest4}";
    };

    aDateInThePark = {
      gameid = "adateinthepark";
      engineid = "ags";
      description = "A Date in the Park";
      platform = "";
      path = "${aDateInThePark}/A Date in the Park";
    };

    leewardEp1 = {
      gameid = "leewardep1";
      engineid = "ags";
      description = "Leeward - Episode 1";
      platform = "";
      path = "${leewardEp1}/Leeward Episode 1";
    };

    suliFallenHarmony = {
      gameid = "sulifallenharmony";
      engineid = "ags";
      description = "Suli Fallen Harmony";
      platform = "";
      path = "${suliFallenHarmony}/Suli FH1.4";
    };
  };
}
