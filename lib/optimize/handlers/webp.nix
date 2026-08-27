{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
let
  buildWebP =
    { suffix, cwebpArgs }:
    src:
    derivation {
      name = "${getName src}-${suffix}.webp";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.libwebp}/bin
          WEBP_INFO=$(webpmux -info "${src}" 2>&1 || true)
          echo "=== DEBUG INFO FOR ${getName src} ==="
          echo "$WEBP_INFO"
          echo "======================================"

          IS_ANIMATED=0

          if [[ "$WEBP_INFO" =~ [Aa]nimation ]]; then
            IS_ANIMATED=1
          elif [[ "$WEBP_INFO" =~ Number[[:space:]]of[[:space:]]frames[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
            FRAMES=''${BASH_REMATCH[1]}
            if [ "$FRAMES" -gt 1 ]; then
              IS_ANIMATED=1
            fi
          fi

          if [ "$IS_ANIMATED" -eq 1 ]; then
            echo "Processing animated WebP via metadata stripping..."
            webpmux -strip icc  "${src}"       -o temp_icc.webp  || cp "${src}" temp_icc.webp
            webpmux -strip exif temp_icc.webp  -o temp_exif.webp || cp temp_icc.webp temp_exif.webp
            webpmux -strip xmp  temp_exif.webp -o tmp.webp       || cp temp_exif.webp tmp.webp
            rm -f temp_icc.webp temp_exif.webp
          else
            echo "Processing static WebP via cwebp..."
            cwebp ${cwebpArgs} "${src}" -o tmp.webp || rm -f tmp.webp
          fi
          ${guardSizeTail "tmp.webp" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
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
