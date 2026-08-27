{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
{
  handler =
    src:
    derivation {
      name = "${getName src}-optimized.wad";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.wadptr}/bin
          # .autosave1-5 (Doom Builder's periodic map backups) are real WAD
          # data with a non-WAD extension, but some are just leftover junk --
          # check the magic before handing them to wadptr, else pass through.
          # wadptr stops parsing flags at the first non-flag argument, so
          # -o must come before the input filename or it's silently treated
          # as part of the (single-file) input list instead.
          case "$(head -c4 "${src}")" in
            PWAD | IWAD) wadptr -c -o tmp.wad "${src}" || rm -f tmp.wad ;;
          esac
          ${guardSizeTail "tmp.wad" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [
    "iwad"
    "autosave1"
    "autosave2"
    "autosave3"
    "autosave4"
    "autosave5"
  ];
}
