{
  config,
  lib,
  fetchGOG,
  getFiles,
  optimize,
  mkRaze,
  ...
}:
let
  sw = config.games.raze.grps.shadowWarrior;
in
lib.mkIf config.games.raze.enable {
  # GOG Complete: base + Wanton Destruction (WT.GRP) + Twin Dragon (dragon/Sw.grp, loose ART/VOC)
  games.raze.grps.shadowWarrior =
    fetchGOG {
      game = "shadow_warrior_complete";
      fileId = "en1installer0";
      sha256 = "sha256-ZCj5P2UW34CMmr373iTurSZelumRor6c8hrNXGa8YuA=";
    }
    |> getFiles [
      "app/Sw.grp"
      "app/Sw.rts"
      "app/WT.GRP"
      "app/MUSIC"
      "app/dragon"
    ];

  # addons find base Sw.grp only via GameSearch dirs; default has ~/.config/raze/* (recursive)
  xdg.configFile."raze/shadowWarrior".source = optimize sw;

  programs.steam.games = {
    SHADOW_WARRIOR = mkRaze {
      name = "Shadow Warrior Classic";
      grp = sw;
      file = "app/Sw.grp";
      steamAppId = 238070;
      gogId = "shadow_warrior_complete";
    };
    SHADOW_WARRIOR_WANTON = mkRaze {
      name = "Shadow Warrior: Wanton Destruction";
      grp = sw;
      file = "app/WT.GRP";
    };
    SHADOW_WARRIOR_TWIN_DRAGON = mkRaze {
      name = "Shadow Warrior: Twin Dragon";
      grp = sw;
      file = "app/dragon/Sw.grp";
    };
  };
}
