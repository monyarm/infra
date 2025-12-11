{
  linkFiles,
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
  xdg.dataFile = linkFiles "scummvm/extra" [
    # keep-sorted start
    "${cm32lRomset}/cm32l_control.rom"
    "${cm32lRomset}/cm32l_pcm.rom"
    # keep-sorted end
  ];
}
