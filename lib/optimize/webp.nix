{ pkgs, guardSize, getName, ... }:
let
  buildWebP =
    { suffix, cwebpArgs }:
    src:
    guardSize (pkgs.runCommand "${getName src}-${suffix}.webp"
      {
        buildInputs = [
          pkgs.libwebp
          pkgs.gnugrep
        ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        # Safe raw info output extraction
        WEBP_INFO=$(webpmux -info "${src}" 2>&1 || true)
        echo "=== DEBUG INFO FOR ${getName src} ==="
        echo "$WEBP_INFO"
        echo "======================================"

        IS_ANIMATED=0

        # Bash regex matching avoids grep/piping entirely, bypassing "broken pipe" errors
        if [[ "$WEBP_INFO" =~ [Aa]nimation ]]; then
          IS_ANIMATED=1
        # Match 'Number of frames' followed by optional spaces, a colon, and grab the digits
        elif [[ "$WEBP_INFO" =~ Number[[:space:]]of[[:space:]]frames[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
          # BASH_REMATCH[1] contains the captured digit group
          FRAMES=''${BASH_REMATCH[1]}
          if [ "$FRAMES" -gt 1 ]; then
            IS_ANIMATED=1
          fi
        fi

        if [ "$IS_ANIMATED" -eq 1 ]; then
          echo "Processing animated WebP via metadata stripping..."
          webpmux -strip icc  "${src}"       -o temp_icc.webp  || cp "${src}" temp_icc.webp
          webpmux -strip exif temp_icc.webp  -o temp_exif.webp || cp temp_icc.webp temp_exif.webp
          webpmux -strip xmp  temp_exif.webp -o "$out"         || cp temp_exif.webp "$out"
          rm -f temp_icc.webp temp_exif.webp
        else
          echo "Processing static WebP via cwebp..."
          cwebp ${cwebpArgs} "${src}" -o "$out"
        fi
      ''
    ) src;
in
{
  normal = buildWebP {
    suffix = "lossless";
    cwebpArgs = "-m 6 -lossless";
  };
  prime = buildWebP {
    suffix = "optimized";
    cwebpArgs = "-m 6 -q 85";
  };
}
