{ config, ... }:
{
  home.sessionPath = [
    "$HOME/Documents/Nim/bin"
    "$HOME/.luarocks/bin"
    "/usr/share/lua/5.1/bin"
    "$HOME/.npm-global/bin"
    "/run/wrappers/bin"
    "$ANDROID_HOME/build-tools/29.0.3"
    "$ANDROID_HOME/cmdline-tools/latest/bin"
    "$ANDROID_HOME/tools"
    "$ANDROID_HOME/platform-tools"
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.dotnet/tools"
    "/opt/bin"
    "/nix/var/nix/profiles/per-user/${config.home.username}/profile/bin"
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  home.sessionSearchVariables = {
    QT_PLUGIN_PATH = [
      "$HOME/.kde4/lib/kde4/plugins/"
      "/usr/lib/kde4/plugins/"
    ];
    STEAM_COMPATIBILITY_TOOLS_D = [
      "$STEAM_COMPATIBILITY_TOOLS_D"
      "$HOME/Games/compatibilitytools.d"
    ];
  };

  programs.zsh.initContent = ''
    export PATH="$(yarn global bin):$PATH"
  '';
}
