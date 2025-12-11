{ config, lib, ... }:
let
  c = config.lib.stylix.colors.withHashtag;

  # Generate baseXX color properties dynamically
  baseColorsQML = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "              readonly property color ${name}: \"${value}\"") (
      lib.filterAttrs (name: _value: lib.strings.hasPrefix "base" name) c
    )
  );

  colors = ''
            // Managed by Home Manager
            pragma Singleton
            import Quickshell
            import QtQuick
            Singleton {
              // Base16 Color Scheme (Default Dark)
              ${baseColorsQML}

    	  // Convenience aliases for common UI elements
    	  readonly property color background: base00
    	  readonly property color surface: base01
    	  readonly property color border: base02
    	  readonly property color comment: base03
    	  readonly property color foreground: base05
    	  readonly property color text: base05
    	  readonly property color accent: base0D
    	  readonly property color error: base08
    	  readonly property color warning: base09
    	  readonly property color success: base0B
    	  readonly property color transparent: "transparent"
    	}
  '';
in
{
  xdg.configFile."quickshell/modules/Color.qml".text = colors;
}
