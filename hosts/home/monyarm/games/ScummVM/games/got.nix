{
  pkgs,
  config,
  lib,
  compressScummvmGame,
  ...
}:
let
  got =
    pkgs.fetchzip {
      url = "https://www.adeptsoftware.com/got/gotfree.zip";
      stripRoot = false;
      hash = "sha256-P7VIPiumqBoDtH6VNHhnf/Q1h509xT6i0A/KZQ8zrXY=";
    }
    |> compressScummvmGame "got";
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games.got = {
    engineid = "got";
    description = "God of Thunder";
    path = "${got}";
  };
}
