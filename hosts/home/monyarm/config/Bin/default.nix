{
  lib,
  pkgs,
  binFiles,
  dirs,
  ...
}:

with lib;

let
  sleepAmount = "5s";
  fehScript = pkgs.writeText "feh-script" ''
    #!/bin/bash
    export DISPLAY=:0
    for i in $(seq 1 19); do # Loop 19 times for sleep
      feh --randomize --bg-fill ${dirs.wallpapers}/*
      sleep ${sleepAmount}
    done
    feh --randomize --bg-fill ${dirs.wallpapers}/*
  '';

  address = "E4:17:D8:CE:B3:0B";
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
in

{
  home.file = binFiles (
    [
      # keep-sorted start
      fehScript
      reconnectScript
      # keep-sorted end
    ]
    ++ (lib.map (name: "${dirs.hmConfig}/Bin/.local/bin/${name}") (
      builtins.attrNames (builtins.readDir ./.local/bin)
    ))
  );
}
