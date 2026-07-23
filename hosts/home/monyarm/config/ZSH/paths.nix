{ config, lib, ... }:
{

  home.sessionSearchVariables = {
    QT_PLUGIN_PATH = [
      "$HOME/.kde4/lib/kde4/plugins/"
      "/usr/lib/kde4/plugins/"
    ];
    STEAM_COMPATIBILITY_TOOLS_D = [
      "$HOME/Games/compatibilitytools.d"
    ];
  };

  home.sessionPath = [
    "$HOME/Documents/Nim/bin"
    "$HOME/.luarocks/bin"
    "/usr/share/lua/5.1/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.cargo/bin"
    "/run/wrappers/bin"
    "$ANDROID_HOME/build-tools/29.0.3"
    "$ANDROID_HOME/cmdline-tools/latest/bin"
    "$ANDROID_HOME/tools"
    "$ANDROID_HOME/platform-tools"
    "$HOME/.local/bin"
    "$HOME/.dotnet/tools"
    "/opt/bin"
    "/nix/var/nix/profiles/per-user/${config.home.username}/profile/bin"
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "$HOME/Applications/flutter"
  ];

  programs.zsh = {
    initContent = ''
      export PATH="${
        # Temporarily set PATH directly to avoid bug with home.sessionPath and zsh.
        lib.concatStringsSep ":" (
          config.home.sessionPath
          ++ [
            "$(yarn global bin)"
            "$PATH"
          ]
        )
      }"
    '';
    profileExtra = lib.optionalString (config.home.sessionPath != [ ]) ''
      export PATH="$PATH''${PATH:+:}${lib.concatStringsSep ":" config.home.sessionPath}"
    '';
  };
}
