{ lib, ... }:
with lib;
let
  defaultApps = {
    text = [ "featherpad.desktop" ];
    image = [ "geeqie.desktop" ];
    audio = [ "mpv.desktop" ];
    video = [ "mpv.desktop" ];
    directory = [ "nemo.desktop" ];
    office = [ "libreoffice.desktop" ];
    pdf = [ "org.pwmt.zathura.desktop" ];
    terminal = [ "ghostty.desktop" ];
    archive = [ "org.kde.ark.desktop" ];
    web = [ "firefox.desktop" ];

    #single
    discord = [ "discord.desktop" ];
    discord-694795560288256021 = [ "discord-694795560288256021.desktop" ]; # required by EdoPro
    r2 = [ "reloaded-ii-url.desktop" ];
    nxm = [ "modorganizer2-nxm.desktop" ];
  };

  mimeMap = {
    text = [
      # keep-sorted start
      "text/plain"
      # keep-sorted end
    ];
    image = [
      # keep-sorted start
      "image/bmp"
      "image/gif"
      "image/jpeg"
      "image/jpg"
      "image/png"
      "image/svg+xml"
      "image/tiff"
      "image/vnd.microsoft.icon"
      "image/webp"
      # keep-sorted end
    ];
    audio = [
      # keep-sorted start
      "audio/aac"
      "audio/flac"
      "audio/midi"
      "audio/mpeg"
      "audio/ogg"
      "audio/opus"
      "audio/wav"
      "audio/webm"
      "audio/x-aiff"
      "audio/x-flac"
      "audio/x-matroska"
      "audio/x-midi"
      "audio/x-mpegurl"
      # keep-sorted end
    ];
    video = [
      # keep-sorted start
      "video/mp2t"
      "video/mp4"
      "video/mpeg"
      "video/ogg"
      "video/webm"
      "video/x-flv"
      "video/x-matroska"
      "video/x-msvideo"
      # keep-sorted end
    ];
    directory = [
      # keep-sorted start
      "inode/directory"
      # keep-sorted end
    ];
    office = [
      # keep-sorted start
      "application/msword"
      "application/rtf"
      "application/vnd.ms-excel"
      "application/vnd.ms-powerpoint"
      "application/vnd.oasis.opendocument.presentation"
      "application/vnd.oasis.opendocument.spreadsheet"
      "application/vnd.oasis.opendocument.text"
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      # keep-sorted end
    ];
    pdf = [
      # keep-sorted start
      "application/pdf"
      "application/vnd.comicbook+zip"
      "application/vnd.comicbook-rar"
      # keep-sorted end
    ];
    terminal = [
      # keep-sorted start
      "terminal"
      # keep-sorted end
    ];
    archive = [
      # keep-sorted start
      "application/*paq"
      "application/*tar"
      "application/7z"
      "application/rar"
      "application/zip"
      # keep-sorted end
    ];
    discord = [
      # keep-sorted start
      "x-scheme-handler/discord"
      # keep-sorted end
    ];
    discord-694795560288256021 = [ "x-scheme-handler/discord-694795560288256021" ]; # required for EdoPro
    web = [
      # keep-sorted start
      "text/html"
      "x-scheme-handler/about"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/unknown"
      # keep-sorted end
    ];
    r2 = [
      # keep-sorted start
      "x-scheme-handler/r2"
      # keep-sorted end
    ];
    nxm = [
      # keep-sorted start
      "x-scheme-handler/nxm"
      "x-scheme-handler/nxm-protocol"
      # keep-sorted end
    ];
  };

  associations =
    with lists;
    listToAttrs (
      flatten (mapAttrsToList (key: map (type: attrsets.nameValuePair type defaultApps."${key}")) mimeMap)
    );
in
{
  xdg.configFile."mimeapps.list".force = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.associations.added = associations;
  xdg.mimeApps.defaultApplications = associations;

  home.sessionVariables = {
    # prevent wine from creating file associations
    WINEDLLOVERRIDES = "winemenubuilder.exe=d";
  };
}
