{ lib, dirs, ... }:

{
  xdg.configFile."KADOKAWA/RPGMV.conf".text = lib.generators.toINI { } {
    General = {
      checkerboardBlue = 255;
      checkerboardGreen = 255;
      checkerboardRed = 255;
      drawingTool = 0;
      editMode = 0;
      location = "${dirs.HOME}/Documents/RPG Maker";
      mapImagesLocation = "";
      mapScreenGrid = false;
      mapScreenGridHeight = 13;
      mapScreenGridWidth = 17;
      mvTools = "";
      objectSelector = "dropdown";
      outputLocation = "${dirs.HOME}/Documents/Output";
      projectFileUrl = "file:///${dirs.HOME}/Documents/RPG Maker/Project1/Game.rpgproject";
      themeName = "dark";
      tileScale = 1.5;
      uploadOperation = 1;
      uploadOperationMonaca = 4;
      uploadOperationOgc = 2;
      windowHeight = 720;
      windowWidth = 1200;
      windowX = 2263;
      windowY = 267;
    };
  };

  xdg.configFile."EasyRPG/EasyRPG Editor.conf".text = lib.generators.toINI { } {
    General = {
      current_project = "test";
      default_dir = "${dirs.HOME}/Documents/";
      rtp_path = "/usr/share/easyrpg/rtp/";
    };
  };
}
