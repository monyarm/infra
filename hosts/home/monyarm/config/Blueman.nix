{
  # Blueman notifies on every Bluetooth connect and disconnect, and the printer
  # link comes and goes with each job. No per-device switch exists, so the
  # notifier plugin is off entirely.
  dconf.enable = true;
  dconf.settings."org/blueman/general".plugin-list = [ "!ConnectionNotifier" ];
}
