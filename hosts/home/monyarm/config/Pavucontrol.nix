{ lib, ... }:

{
  xdg.configFile."pavucontrol.ini".text = lib.generators.toINI { } {
    window = {
      width = 936;
      height = 1018;
      sinkInputType = 1;
      sourceOutputType = 1;
      sinkType = 0;
      sourceType = 1;
      showVolumeMeters = 1;
    };
  };
}
