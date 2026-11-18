{
  pkgs,
  ...
}:
{
  # snd is a web app served on :7123, no window of its own.
  systemd.user.services.snd = {
    Unit.Description = "Sales & Dungeons";
    Service = {
      ExecStart = "${pkgs.snd}/bin/snd";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
