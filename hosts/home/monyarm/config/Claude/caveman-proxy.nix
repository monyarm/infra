{ pkgs, ... }:
{
  # caveman-proxy crashes intermittently (SIGBUS in modernc.org/sqlite's mmap'd
  # WAL writer). This unit's only job is restart-on-death.
  #
  # Runs `caveman start`, not the bare caveman-proxy binary: `start` sets the
  # CAVEMAN_PROXY_OWNER/CAVEMAN_RECOVERY runtime-state env that `caveman wrap`
  # checks before reusing a running proxy -- without it every wrap invocation
  # sees owner "unknown" and refuses to compress through it. `start` also
  # exits 0 on a clean SIGTERM (the handoff `caveman wrap` itself performs
  # when it needs to restart the proxy for a different mode/gate), so
  # Restart=on-failure only fires on genuine crashes, never on that handoff.
  systemd.user.services.caveman-proxy = {
    Unit.Description = "Caveman compression proxy";
    Service = {
      ExecStart = "${pkgs.caveman-cli}/bin/caveman start";
      Environment = "CAVEMAN_MODE=compress";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
