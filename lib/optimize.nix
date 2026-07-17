{
  pkgs,
  lib,
  listFilesRecursive,
  getFileName,
  removeExtension,
  sanitizeName,
  rename,
  dispatchExt,
  parallel,
  ...
}:

let
  getName = src: sanitizeName (removeExtension (getFileName src));

  guardSize =
    originalDrv: src:
    derivation {
      name = "${originalDrv.name}-g";
      system = pkgs.stdenv.hostPlatform.system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          origSize=$(${pkgs.coreutils}/bin/stat -L -c%s "${src}")
          optSize=$(${pkgs.coreutils}/bin/stat -L -c%s "${originalDrv}")
          if [ "$optSize" -gt "$origSize" ]; then
            ${pkgs.coreutils}/bin/cp "${src}" "$out"
          else
            ${pkgs.coreutils}/bin/cp "${originalDrv}" "$out"
          fi
          exit 0; # fix for 2176?
        ''
      ];
      preferLocalBuild = true;
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };
in
rec {
  # --- PNG UTILITIES ---
  pngquant =
    src:
    guardSize (pkgs.runCommand "${getName src}-quantized.png"
      {
        buildInputs = [ pkgs.pngquant ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.png
        chmod +w tmp.png
        pngquant --quality=80-98 --skip-if-larger --ext .png --force tmp.png || true
        mv tmp.png "$out"
      ''
    ) src;

  oxipng =
    level: src:
    guardSize (pkgs.runCommand "${getName src}-oxipng.png"
      {
        buildInputs = [ pkgs.oxipng ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.png
        chmod +w tmp.png
        oxipng -o ${toString level} --strip all --alpha tmp.png
        mv tmp.png "$out"
      ''
    ) src;

  optipng =
    src:
    guardSize (pkgs.runCommand "${getName src}-optipng.png"
      {
        buildInputs = [ pkgs.optipng ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.png
        chmod +w tmp.png
        optipng -o7 -quiet tmp.png
        mv tmp.png "$out"
      ''
    ) src;

  advpng =
    src:
    guardSize (pkgs.runCommand "${getName src}-advpng.png"
      {
        buildInputs = [ pkgs.advancecomp ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.png
        chmod +w tmp.png
        advpng -z -4 tmp.png
        mv tmp.png "$out"
      ''
    ) src;

  # --- JPEG UTILITIES ---
  jpegoptim =
    src:
    guardSize (pkgs.runCommand "${getName src}-jpegoptim.jpg"
      {
        buildInputs = [ pkgs.jpegoptim ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.jpg
        jpegoptim --strip-all --all-normal tmp.jpg
        mv tmp.jpg "$out"
      ''
    ) src;

  mozjpeg =
    src:
    guardSize (pkgs.runCommand "${getName src}-mozjpeg.jpg"
      {
        buildInputs = [ pkgs.mozjpeg ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cjpeg -quality 85 -optimize "${src}" > "$out"
      ''
    ) src;

  guetzli =
    src:
    guardSize (pkgs.runCommand "${getName src}-guetzli.jpg"
      {
        buildInputs = [
          pkgs.guetzli
          pkgs.imagemagick
        ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        # guetzli is incredibly strict about color profiles and input formatting.
        # We use ImageMagick to safely export a temporary, pristine sRGB progressive JPEG 
        # with zero compression artifacts for guetzli to feed on.
        magick "${src}" -colorspace sRGB -strip tmp_input.jpg

        echo "Starting deep psychovisual optimization loop via guetzli..."
        # --quality 84 is guetzli's sweet spot (perceptually matches mozjpeg 90+)
        guetzli --quality 84 tmp_input.jpg "$out"
      ''
    ) src;

  # --- NATIVE WEBP UTILITIES ---

  # Base utility to avoid code repetition
  # TODO: Investigate why some, but not other CA derivations fail on remote builders with file not found?. Could be race condition?
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

  # Lossy optimization (using the base function)
  nativeWebP = buildWebP {
    suffix = "optimized";
    cwebpArgs = "-m 6 -q 85";
  };

  # Lossless optimization (using the base function)
  nativeWebPLossless = buildWebP {
    suffix = "lossless";
    cwebpArgs = "-m 6 -lossless";
  };

  # --- COMPOSITION PIPELINES BY FORMAT ---
  pngPipelinePrime =
    src:
    src
    |> (oxipng 4)
    |> optipng
    |> advpng;
  pngPipeline = src: src |> pngquant |> pngPipelinePrime;

  jpegPipelinePrime = src: src |> jpegoptim;
  jpegPipeline = src: src |> mozjpeg;

  webpPipelinePrime = src: src |> nativeWebPLossless;
  webpPipeline = src: src |> nativeWebP;

  # --- DISPATCH ENGINE ---

  optimizeWith =
    {
      prime ? false,
    }:
    src:
    let

      # Prepare our extension router map dynamically based on the 'prime' flag
      pipelineMap = dispatchExt {
        ".png" = if prime then pngPipelinePrime else pngPipeline;
        ".jpg" = if prime then jpegPipelinePrime else jpegPipeline;
        ".jpeg" = if prime then jpegPipelinePrime else jpegPipeline;
        ".webp" = if prime then webpPipelinePrime else webpPipeline;

        "thumbs.db" = src: src;

        "_" = src: builtins.throw "unknown extension: ${toString src}";
      };
    in
    src |> pipelineMap |> rename src;

  # --- PUBLIC API ---

  optimize = optimizeWith { prime = false; };
  optimize' = optimizeWith { prime = true; };

  optimizeBulkImpl =
    prime: folderSrc:
    let
      allFiles = listFilesRecursive folderSrc;

      entries = parallel (map (filePath: {
        name = builtins.unsafeDiscardStringContext (
          lib.strings.removePrefix "${folderSrc}/" (toString filePath)
        );
        path = optimizeWith { inherit prime; } (
          builtins.path {
            name = sanitizeName (getFileName filePath);
            path = filePath;
          }
        );
      })) allFiles;
    in
    pkgs.linkFarm "${getName folderSrc}-optimized-dir" entries;

  optimizeBulk' = optimizeBulkImpl true;
  optimizeBulk = optimizeBulkImpl false;
}
