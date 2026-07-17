{ lib, ... }:

{
  xdg.configFile."gtk-2.0/gtkfilechooser.ini".text = lib.generators.toINI { } {
    "Filechooser Settings" = {
      LocationMode = "path-bar";
      ShowHidden = false;
      ShowSizeColumn = true;
      GeometryX = 2263;
      GeometryY = 215;
      GeometryWidth = 1316;
      GeometryHeight = 773;
      SortColumn = "name";
      SortOrder = "ascending";
      StartupMode = "recent";
    };
  };
}
