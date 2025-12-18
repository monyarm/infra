{
  config,
  lib,
  ...
}:

let
  mod = config.xsession.windowManager.i3.config.modifier;
in
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      fonts = {
        names = [
          # keep-sorted start
          "Noto Sans Regular"
          # keep-sorted end
        ];
        size = lib.mkForce 9.0;
      };
      floating.modifier = mod;

      # Keybindings
      keybindings = {
        # keep-sorted start
        "${mod}+0" = "workspace 10";
        "${mod}+1" = "workspace 1";
        "${mod}+2" = "workspace 2";
        "${mod}+3" = "workspace 3";
        "${mod}+4" = "workspace 4";
        "${mod}+5" = "workspace 5";
        "${mod}+6" = "workspace 6";
        "${mod}+7" = "workspace 7";
        "${mod}+8" = "workspace 8";
        "${mod}+9" = "workspace 9";
        "${mod}+Down" = "focus down";
        "${mod}+Left" = "focus left";
        "${mod}+Return" = "exec xfce4-terminal";
        "${mod}+Right" = "focus right";
        "${mod}+Shift+0" = "move container to workspace 10";
        "${mod}+Shift+1" = "move container to workspace 1";
        "${mod}+Shift+2" = "move container to workspace 2";
        "${mod}+Shift+3" = "move container to workspace 3";
        "${mod}+Shift+4" = "move container to workspace 4";
        "${mod}+Shift+5" = "move container to workspace 5";
        "${mod}+Shift+6" = "move container to workspace 6";
        "${mod}+Shift+7" = "move container to workspace 7";
        "${mod}+Shift+8" = "move container to workspace 8";
        "${mod}+Shift+9" = "move container to workspace 9";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Return" = "exec --no-startup-id thunar";
        "${mod}+Shift+Right" = "move right";
        "${mod}+Shift+Tab" = "move workspace to output left";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+d" = "exec dmenu_run";
        "${mod}+Shift+j" = "move left";
        "${mod}+Shift+k" = "move down";
        "${mod}+Shift+l" = "move up";
        "${mod}+Shift+minus" = "move scratchpad";
        "${mod}+Shift+q" = "kill";
        "${mod}+Shift+r" = "restart";
        "${mod}+Shift+semicolon" = "move right";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+Tab" = "move workspace to output right";
        "${mod}+Up" = "focus up";
        "${mod}+a" = "focus parent";
        "${mod}+d" = "exec --no-startup-id xfce4-popup-whiskermenu";
        "${mod}+e" = "layout toggle split";
        "${mod}+f" = "fullscreen toggle";
        "${mod}+h" = "split h";
        "${mod}+j" = "focus left";
        "${mod}+k" = "focus down";
        "${mod}+l" = "focus up";
        "${mod}+minus" = "scratchpad show";
        "${mod}+r" = "mode \"resize\"";
        "${mod}+s" = "layout stacking";
        "${mod}+semicolon" = "focus right";
        "${mod}+space" = "focus mode_toggle";
        "${mod}+v" = "split v";
        "${mod}+w" = "layout tabbed";
        "Print" = "exec --no-startup-id xfce4-screenshooter";
        # keep-sorted end
      };

      # Modes
      modes = {
        resize = {
          j = "resize shrink width 10 px or 10 ppt";
          k = "resize grow height 10 px or 10 ppt";
          l = "resize shrink height 10 px or 10 ppt";
          semicolon = "resize grow width 10 px or 10 ppt";
          Left = "resize shrink width 10 px or 10 ppt";
          Down = "resize grow height 10 px or 10 ppt";
          Up = "resize shrink height 10 px or 10 ppt";
          Right = "resize grow width 10 px or 10 ppt";
          Return = "mode default";
          Escape = "mode default";
        };
      };

      # Window rules
      window.commands = [
        {
          criteria = {
            class = ".*";
          };
          command = "border pixel 0";
        }
        {
          criteria = {
            class = "Toplevel";
            instance = "configureServer.*";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "java-lang-Thread";
            instance = "java-lang-Thread";
            title = "IcedTea-Web Control Panel";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Xfce4-appfinder";
            instance = "xfce4-appfinder";
            title = "Application Finder";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Wrapper-1.0";
            instance = "wrapper-1.0";
            title = "Notification Area";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Wrapper-2.0";
            instance = "wrapper-2.0";
            title = "PulseAudio Panel Plugin";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Xfce4-panel";
            instance = "xfce4-panel";
            title = "Clock";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Xfce4-panel";
            instance = "xfce4-panel";
            title = "Panel";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Xfce4-panel";
            instance = "xfce4-panel";
            title = "Separator";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Xfce4-panel";
            instance = "xfce4-panel";
            title = "Add New Items";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Pamac-manager";
            instance = "pamac-manager";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Pamac-updater";
            instance = "pamac-updater";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Xfce4-terminal";
            instance = "xfce4-terminal";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Empathy";
            instance = "empathy";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Xsane";
            instance = "xsane";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Redshiftgui.elf";
            instance = "redshiftgui.elf";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "etcher-electron";
            instance = "etcher-electron";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Pavucontrol";
            instance = "pavucontrol";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "Blueman-manager";
            instance = "blueman-manager";
          };
          command = "floating enable";
        }
        {
          criteria = {
            class = "TelegramDesktop";
            instance = "telegram-desktop";
          };
          command = "floating enable";
        }
        {
          criteria = {
            instance = ".*crx.*";
            window_role = "pop-up";
          };
          command = "floating enable";
        }
        {
          criteria = {
            instance = ".*crx.*";
            window_role = "pop-up";
          };
          command = "sticky enable";
        }
        {
          criteria = {
            class = "Xfce4-panel";
            instance = "xfce4-panel";
          };
          command = "floating enable";
        }
      ];

      # Gaps settings
      gaps = {
        inner = 5;
        outer = 0;
        smartBorders = "on"; # "on" or "off" or "no_gaps"
        smartGaps = true; # boolean
      };

      # Startup commands
      startup = [
        {
          command = "xfce4-panel --disable-wm-check &";
          always = false;
          notification = false;
        }
        {
          command = "xfsettingsd &";
          always = false;
          notification = false;
        }
        {
          command = "/usr/libexec/xfce-polkit &";
          always = false;
          notification = false;
        }
        {
          command = "synergy";
          always = false;
          notification = false;
        }
        {
          command = "compton";
          always = false;
          notification = false;
        }
        {
          command = "devilspie";
          always = false;
          notification = false;
        }
        {
          command = "feh --randomize --bg-fill ~/Pictures/wallpapers/*";
          always = false;
          notification = false;
        }
        {
          command = "dropbox stop && dbus-launch dropbox start";
          always = false;
          notification = false;
        }
        {
          command = "/usr/lib/x86_64-linux-gnu/bamf/bamfdaemon";
          always = true;
          notification = false;
        }
        {
          command = "/home/monyarm/.local/bin/setup_rclone";
          always = true;
          notification = false;
        }
        {
          command = "ibus-daemon";
          always = false;
          notification = false;
        }
      ];
    };
  };
}
