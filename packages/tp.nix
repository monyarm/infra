{
  lib,
  pkgs,
  ...
}:

let
  # Absolute paths baked in: the script runs from a bare store path, with no
  # wrapper to set env vars.
  script =
    builtins.replaceStrings
      [ "@FONT@" "@PDFTOTEXT@" "@FCMATCH@" ]
      [
        "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf"
        "${pkgs.poppler-utils}/bin/pdftotext"
        "${pkgs.fontconfig}/bin/fc-match"
      ]
      (builtins.readFile ./tp.py);

  cli = pkgs.writers.writePython3Bin "tp" {
    libraries = [ pkgs.python3Packages.pillow ];
    flakeIgnore = [
      "E203"
      "E501"
      "W503"
    ];
  } script;
in
pkgs.runCommand "tp"
  {
    meta = {
      description = "ESC/POS thermal printer CLI and CUPS backend over Bluetooth SPP";
      license = lib.licenses.mit;
      mainProgram = "tp";
      platforms = lib.platforms.linux;
    };
  }
  ''
    mkdir -p $out/bin $out/lib/cups/backend
    ln -s ${cli}/bin/tp $out/bin/tp
    ln -s ${cli}/bin/tp $out/lib/cups/backend/thermal
  ''
