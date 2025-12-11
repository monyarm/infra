{
  ...
}:

{
  imports = [
    # keep-sorted start
    ./script-opts/celebi.nix
    ./script-opts/coverart.nix
    ./script-opts/dvd_browser.nix
    ./script-opts/evafast.nix
    ./script-opts/lrc.nix
    ./script-opts/memo.nix
    ./script-opts/mpv360.nix
    ./script-opts/mpvremote.nix
    ./script-opts/segment_linking.nix
    ./script-opts/sponsorblock_minimal.nix
    ./script-opts/thumbfast.nix
    ./script-opts/uosc.nix
    ./script-opts/uosc_subtitle_settings.nix
    ./script-opts/uosc_video_settings.nix
    ./script-opts/webtorrent.nix
    # keep-sorted end
  ];

  # xdg.configFile entries for uosc are now handled by individual Nix files.
}
