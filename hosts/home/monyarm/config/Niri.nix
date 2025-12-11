{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.niri.package = pkgs.niri;
  programs.niri.settings = {
    input = {
      keyboard = {
        xkb.layout = "gb,bg(phonetic)";
        numlock = true;
      };
      tablet = {
        enable = true;
        map-to-output = "DP-3";
      };
      mouse = {
        enable = true;
      };
    };
    layout = {
      border = {
        width = 1;
      };
      gaps = 4;
      always-center-single-column = true;
    };
    environment = {
      DISPLAY = ":0";
      # keep-sorted start
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      GDK_BACKEND = "wayland,x11";
      GNUPGHOME = config.sops.gnupg.home;
      GTK_USE_PORTAL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_LEGACY_PROFILES = "1";
      # keep-sorted end
    }
    // config.sops.environment;
    spawn-at-startup =
      let
        split = list: builtins.map (x: { argv = lib.toList (lib.splitString " " x); }) list;
      in
      split [
        # keep-sorted start
        "/usr/libexec/polkit-mate-authentication-agent-1"
        "gentoo-pipewire-launcher"
        "quickshell"
        "swww-daemon"
        "xwayland-satellite"
        "~/.local/bin/swww-random"
        (builtins.head config.systemd.user.services.sops-nix.Service.ExecStart)
        # keep-sorted end
      ];
    prefer-no-csd = true;
    window-rules = [

      {
        matches = [
          { is-floating = true; }
        ];
        baba-is-float = true;
      }
      {
        matches = [
          {
            app-id = "steam";
            title = "^notificationtoasts_\d+_desktop$";
          }
        ];
        default-floating-position = {
          x = 10;
          y = 10;
          relative-to = "top-right";
        };
      }
      {
        matches = [ { app-id = "wezterm"; } ];
        default-column-width = { };
      }
      {
        matches = [
          {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          }
          {
            app-id = "^(eroge|kenzen2).exe";
            title = "Confirm";
          }
        ];
        open-floating = true;
        open-fullscreen = false;
      }
      {
        matches = [
          { app-id = "^org\.keepassxc\.KeePassXC$"; }
          { app-id = "^org\.gnome\.World\.Secrets$"; }
        ];
        block-out-from = "screen-capture";
      }
      {
        matches = [
          { app-id = "firefox$"; }
        ];
        clip-to-geometry = true;
        draw-border-with-background = false;
      }
      {
        matches = [
          {
            app-id =
              let
                modpacks = lib.concatMapStringsSep "|" (x: "(${x})") [
                  "GT: New Horizons"
                  "Better than Adventure"
                ];
              in
              "(${modpacks}) ?((v|V|version|Version)(.|:| )?)?([0-9]+\\.?)?";
          }
          {
            app-id = "Minecraft\\* 1\\.[0-9]{2}\\.[0-9]";
            title = "Minecraft:? ((Forge|NeoForge|Fabric|Quilt)\\*? )?((1\\.[0-9]{2}\\.[0-9])|(Loading\\.\\.\\.))";
          }
          {
            app-id =
              let
                apps = lib.concatMapStringsSep "|" (x: "(${x})") [
                  "PokeRogue"
                  "Funkin"
                  "scummvm"
                  "edopro"
                  "steam_app_[0-9]+"
                  "mpv"
                  "Game(\\.x86)?"
                  "gun knight"
                  "(g|u)?zdoom"
                  (
                    "("
                    + (lib.concatMapStringsSep "|" (x: "(${x})") [
                      "game"
                      "eroge"
                      "kenzen2"
                      "hhs\\+"
                      "the midnight channel"
                      "mkxp(-console)?"
                      "su_[0-9]\\.[0-9]\\.[0-9]"
                      "pda_personal_data_altercator_"
                      "narbacular drop"
                      "nitronicrush"
                      "perspective"
                      "tag"
                      "lose95"
                      "minidoom2 v[0-9]-[0-9]-[0-9]"
                      "roguelight"
                    ])
                    + ").exe"
                  )
                ];
              in
              "^(${apps})$";
          }
          {
            title =
              let
                titles = lib.concatMapStringsSep "|" (x: "(${x})") [
                  # RenPy
                  "Another Truth"
                  "AshfordAcademyRedux"
                  "AmityPark"
                  "Battle Sisters"
                  "CorruptedAcademy"
                  "EarnYourFreedom3D"
                  "Four Elements Trainer"
                  "Full Service Shop"
                  "Futagenesis Unveiled"
                  "Haramase Simulator"
                  "Hazelnut Latte"
                  "Honey Kingdom"
                  "Innocent Witches"
                  "IA"
                  "Katawa Shoujo"
                  "Magic Shop [0-9].[0-9]{2}"
                  "MayasMission"
                  "MythicManor"
                  "Orange Trainer"
                  "Pandora's Box"
                  "Paprika Trainer"
                  "PokeSluts"
                  "re:Dreamer"
                  "Rogue-Like"
                  "Seeds of Chaos"
                  "Surrendering to my crush"
                  "SummertimeSaga"
                  "The Potion Room"
                  "Tuition Academia"
                  "Witch Hunter"
                  "WTS"
                  "Naked Ambition \\.[0-9]+"
                  "Princess Trainer Gold Edition [0-9]\\.[0-9]+"
                  "Take Over"
                  # Not Ren'Py
                  "Transformation Tycoon"
                  "Open Sonic [0-9]\\.[0-9]\\.[0-9]"
                ];
              in
              "^${titles}$";
          }
          {
            app-id = "git.exe"; # Text Adventure Engine
          }
        ];
        open-fullscreen = true;
      }
    ];

    binds = lib.mergeAttrsList (
      with config.lib.niri.actions;
      [
        # Multimedia
        {
          "XF86AudioPlay".action = spawn "playerctl" "play-pause";
          "XF86AudioPause".action = spawn "playerctl" "pause";
          "XF86AudioNext".action = spawn "playerctl" "next_track";
          "XF86AudioPrev".action = spawn "playerctl" "prev_track";

          "XF86AudioMute".action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";

          "XF86AudioRaiseVolume".action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+";
          "XF86AudioLowerVolume".action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";

          # Screen
          "XF86MonBrightnessUp".action = spawn "brightnessctl" "set" "10%+";
          "XF86MonBrightnessDown".action = spawn "brightnessctl" "set" "10%-";

          # Keyboard
          "Shift+XF86MonBrightnessUp".action = spawn "brightnessctl" "--device=kbd_backlight" "set" "10%+";
          "Shift+XF86MonBrightnessDown".action = spawn "brightnessctl" "--device=kbd_backlight" "set" "10%-";

          # Screenshot
          "Print".action.screenshot = {
            show-pointer = false;
          };
          "Ctrl+Print".action.screenshot-screen = {
            write-to-disk = false;
          };
          "Alt+Print".action.screenshot-window = {
            write-to-disk = false;
          };
        }

        # Bindings
        {

          "Mod+Return" = {
            repeat = false;
            action = spawn "ghostty";
          };
          "Mod+Shift+Return" = {
            repeat = false;
            action = spawn "xterm";
          };

          "Mod+D" = {
            repeat = false;
            action = spawn "fuzzel";
          };

          "Mod+V" = {
            repeat = false;
            action = spawn "cliphist" "list" "|" "fuzzel" "-d" "|" "cliphist" "decode" "|" "wl-copy";
          };

          # TODO: Install grimshot or find a way to get it working without sway (gentoo package requires sway)
          # "Mod+Shift+S" = { repeat = false; action = spawn "wayfreeze" "--after-freeze-cmd" "grim -g $(slurp) - | wl-copy; killall wayfreeze";};
          #"Mod+Shift+S" = { repeat = false; action = spawn "wayfreeze" "--after-freeze-cmd" "grimshot --notify --cursor copy area; killall wayfreeze";};
          #"Mod+Shift+D" = { repeat = false; action = spawn "sh" "-c" "grim -g '$(slurp)' - | tesseract - - -l jpn | wl-copy"; };

          "Mod+Ctrl+Q" = {
            repeat = false;
            action = spawn "sh" "-c" "pgrep swaylock || swaylock --image ${config.stylix.image}";
          };

          "Mod+Q" = {
            repeat = false;
            action = close-window;
          };
          "Mod+S".action = switch-preset-column-width;
          "Mod+F".action = maximize-column;
          "Mod+Shift+F".action = fullscreen-window;
          "Mod+W".action = toggle-column-tabbed-display;

          "Mod+Comma".action = consume-window-into-column;
          "Mod+Period".action = expel-window-from-column;
          "Mod+Tab".action = switch-focus-between-floating-and-tiling;
          "Mod+Shift+Space".action = toggle-window-floating;
        }

        # Workspace
        (
          let
            workspaces = builtins.genList (i: {
              key = builtins.toString (lib.trivial.mod (i + 1) 10);
              index = i + 1;
            }) 10;
          in
          lib.mergeAttrsList [
            # Mod+N focus workspace N
            (builtins.listToAttrs (
              map (w: {
                name = "Mod+" + w.key;
                value = {
                  action.focus-workspace = w.index;
                };
              }) workspaces
            ))

            # Mod+Shift+N move window to workspace N
            (builtins.listToAttrs (
              map (w: {
                name = "Mod+Shift+" + w.key;
                value = {
                  action.move-window-to-workspace = w.index;
                };
              }) workspaces
            ))

            {
              "Mod+H".action = focus-column-or-monitor-left;
              "Mod+J".action = focus-window-or-workspace-down;
              "Mod+K".action = focus-window-or-workspace-up;
              "Mod+L".action = focus-column-or-monitor-right;

              "Mod+Left".action = focus-column-or-monitor-left;
              "Mod+Down".action = focus-window-or-workspace-down;
              "Mod+Up".action = focus-window-or-workspace-up;
              "Mod+Right".action = focus-column-or-monitor-right;

              "Mod+Shift+H".action = move-column-left;
              "Mod+Shift+J".action = move-column-to-workspace-down;
              "Mod+Shift+K".action = move-column-to-workspace-up;
              "Mod+Shift+L".action = move-column-right;

              "Mod+Shift+Left".action = move-column-left-or-to-monitor-left;
              "Mod+Shift+Down".action = move-column-to-workspace-down;
              "Mod+Shift+Up".action = move-column-to-workspace-up;
              "Mod+Shift+Right".action = move-column-right-or-to-monitor-right;
            }
          ]
        )
      ]
    );
  };
}
