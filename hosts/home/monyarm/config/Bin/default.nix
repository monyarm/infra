{
  lib,
  pkgs,
  binFiles,
  dirs,
  parallel,
  getFile,
  sources,
  fetchGitTree,
  bluetoothMacs,
  ...
}:

with lib;

let
  commonYdlArgs = "-i -N 8 --external-downloader aria2c";
  commonVideoArgs = "--sub-lang \"all\" --embed-subs --embed-chapters --merge-output-format mkv -o %(title)s.%(ext)s";
  kodiPluginUrl = "plugin://plugin.video.sendtokodi?";

  mkYdl =
    name: extraArgs:
    pkgs.writeText "ydl${if name == "" then "" else "-${name}"}" ''
      #!/bin/bash
      set -f
      yt-dlp ${commonYdlArgs} ${extraArgs} "$1"
    '';

  ydlScripts = [
    (mkYdl "" "-f bestvideo+bestaudio ${commonVideoArgs}")
    (mkYdl "wav" "--extract-audio --audio-format wav")
    (mkYdl "480" "-f \"bestvideo[height<=480][ext=mp4]+bestaudio/[height <=? 480]\" ${commonVideoArgs}")
  ];

  commonVideoExtensions = "mp4|webm|mkv|avi|flv|wmv|mov|m4a|3gp|ts";

  mkYdlBulk =
    name: ydlCmd: fileExt:
    pkgs.writeText "ydl-bulk-${name}" ''
      #!/bin/bash
      regexGeneric="((http[s]*):\/\/)*(.*)(${fileExt})/gi"
      regexPlaylist="((http[s]*):\/\/)www.youtube.com\/((playlist\?list=)|(user\/.*))(.*)/gi"
      for i in "$@"
        do 
          if [[ $i =~ $regexGeneric ]]; then
            curl -O -J -L "$i"
          else
            ${ydlCmd} "$i"
          fi
        done
    '';

  ydlBulkScripts = [
    (mkYdlBulk "default" "ydl" commonVideoExtensions)
    (mkYdlBulk "wav" "ydlwav" "wav")
    (mkYdlBulk "480" "ydl480" commonVideoExtensions)
  ];

  # Generate ydl-strm scripts for Kodi
  ydlStrmScript = pkgs.writeText "ydl-strm" ''
    #!/bin/bash
    echo '${kodiPluginUrl}'"''${1%%\&*} " >>"''${2%.*}".strm
  '';

  ydlStrmBulkScript = pkgs.writeText "ydl-strm-bulk" ''
    #!/bin/bash
    yt-dlp -i --playlist-reverse -j --flat-playlist "$1" | jq -r --tab '.title + "\t" + "${kodiPluginUrl}" + .url' | awk '{f=$1".strm";sub(/[^\11\12\15\40-\176]/,"",f);gsub(/[\\\|\/]/, "",f); print $2 >f}' FS='\t'
    rm -rf \[Private\ video\].strm
  '';

  address = bluetoothMacs.proController;
  reconnectScript = pkgs.writeText "reconnect" ''
    '
          #!/usr/bin/expect
          set prompt "#"
          # set address ${address} # Removed, as it's directly interpolated

          send_user "\nDisconnecting Pro Controller.\r"
          spawn bluetoothctl
          expect -re $prompt
          expect "Agent registered"
          send "disconnect ${address}\r" # Interpolated
          sleep 2
          expect "Successful disconnected"
          send "remove ${address}\r" # Interpolated
          sleep 2
          expect "Device has been removed"
          send "scan on\r"
          sleep 2
          expect "\[NEW\] Device ${address} Pro Controller" # Interpolated, square brackets escaped
          send_user "Pro Controller Discovered\r"
          sleep 2
          send "pair ${address}\r" # Interpolated
          expect "Pairing successful"
          sleep 2
          send "trust ${address}\r" # Interpolated
          expect "trust succeeded"
          sleep 2
          send "connect ${address}\r" # Interpolated
          expect "Connection successful"
          sleep 2
          send "quit\r"
          spawn zenity --info --text "Press L+R to pair Pro Controller"
          expect eof
  '';
  Extract = (fetchGitTree sources.xvoland.extract) |> getFile "extract.sh";
in

{
  home.packages = with pkgs; [
    yt-dlp
    aria2
    expect
  ];

  home.file = binFiles (
    [
      # keep-sorted start
      (import ./nxm.nix { inherit pkgs dirs; })
      Extract
      reconnectScript
      ydlStrmBulkScript
      ydlStrmScript
      # keep-sorted end
    ]
    ++ ydlScripts
    ++ ydlBulkScripts
    ++ (parallel (map (name: "${dirs.hmConfig}/Bin/.local/bin/${name}")) (
      builtins.attrNames (builtins.readDir ./.local/bin)
    ))
  );

}
