{ pkgs, ... }:
{
  # Always-on local gateway -- Claude (and future tools) talk to it via
  # ANTHROPIC_BASE_URL instead of hitting providers directly. No config-path
  # override: keeps OmniRoute's own npm-run defaults.
  systemd.user.services.omniroute = {
    Unit.Description = "OmniRoute local AI gateway";
    Service = {
      ExecStart = "${pkgs.omniroute}/bin/omniroute";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
