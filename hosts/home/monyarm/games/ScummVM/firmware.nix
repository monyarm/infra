{
  pkgs,
  ...
}:

let
  cm32lRomset = pkgs.fetchzip {
    url = "https://archive.org/download/mame251/cm32l.zip";
    sha256 = "sha256-gN8n++qPVYK59OmX9JztqWySnT1jT1zaXJsBKFLzXOI=";
    stripRoot = false;
  };
in
{
  games.scummvm.firmware = {
    cm32lControl = "${cm32lRomset}/cm32l_control.rom";
    cm32lPcm = "${cm32lRomset}/cm32l_pcm.rom";
  };
}
