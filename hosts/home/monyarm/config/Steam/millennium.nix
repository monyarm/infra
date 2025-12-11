{ lib, ... }:

{
  xdg.configFile."millennium/millennium.ini".text = lib.generators.toINI { } {
    Settings = {
      enabled_plugins = lib.strings.concatStringsSep "|" [
        # keep-sorted start
        "achievement-groups"
        "augmented-steam"
        "core"
        "extendium"
        "steam-collections-plus"
        "steam-db"
        "steam-easygrid"
        # keep-sorted end
      ];
    };
    PackageManager = {
      dev_packages = "no";
      auto_update_dev_packages = "yes";
      use_pip = "yes";
    };
  };

  xdg.configFile."millennium/config.json".text = lib.generators.toJSON { } {
    general = {
      injectJavascript = true;
      injectCSS = true;
      checkForMillenniumUpdates = true;
      checkForPluginAndThemeUpdates = true;
      onMillenniumUpdate = 2;
      shouldShowThemePluginUpdateNotifications = true;
      accentColor = "DEFAULT_ACCENT_COLOR";
    };
    misc = {
      hasShownWelcomeModal = true;
    };
    themes = {
      activeTheme = "default";
      allowedStyles = true;
      allowedScripts = true;
      conditions = { };
    };
    notifications = {
      showNotifications = true;
      showUpdateNotifications = true;
      showPluginNotifications = true;
    };
  };
}
