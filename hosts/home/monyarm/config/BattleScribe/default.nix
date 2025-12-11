{ mkOutOfStoreSymlink, dirs, ... }:
{
  home.file = {
    ".battlescribe".source = mkOutOfStoreSymlink "${dirs.hmConfig}/BattleScribe/.battlescribe";
    "BattleScribe/rosters".source =
      mkOutOfStoreSymlink "${dirs.hmConfig}/BattleScribe/BattleScribe/rosters";
    "BattleScribe/settings".source =
      mkOutOfStoreSymlink "${dirs.hmConfig}/BattleScribe/BattleScribe/settings";
  };
}
