{
  pkgs,
  lib,
  getFileName,
  removeExtension,
  parallel,
  ...
}:
rec {
  standardResolutions = {
    "16:9" = [
      {
        w = 1280;
        h = 720;
      }
      {
        w = 1920;
        h = 1080;
      }
      {
        w = 2560;
        h = 1440;
      }
      {
        w = 3840;
        h = 2160;
      }
      {
        w = 7680;
        h = 4320;
      }
    ];
    "4:3" = [
      {
        w = 1024;
        h = 768;
      }
      {
        w = 1280;
        h = 960;
      }
      {
        w = 1600;
        h = 1200;
      }
      {
        w = 2048;
        h = 1536;
      }
    ];
    "21:9" = [
      {
        w = 2560;
        h = 1080;
      }
      {
        w = 3440;
        h = 1440;
      }
      {
        w = 5120;
        h = 2160;
      }
    ];
  };

  capitalize =
    s: lib.toUpper (lib.substring 0 1 s) + lib.substring 1 (lib.stringLength s) s;

  foldAttrs = f: list: lib.foldl' (acc: x: acc // f x) { } list;

  image =
    let
      # Define aspect ratios and their normalized names
      aspectRatios = {
        "16:9" = "16x9";
        # Add more aspect ratios here as needed
        # "4:3" = "4x3";
        # "21:9" = "21x9";
      };

      # Define gravities
      gravities = [
        "center"
        "north"
        "south"
        "east"
        "west"
        "northeast"
        "northwest"
        "southeast"
        "southwest"
      ];

      # Generate crop functions for each aspect ratio and gravity combination
      generateCropFunctions = foldAttrs (
        aspectRatio:
        let
          normalizedName = aspectRatios.${aspectRatio};
        in
        { "crop${normalizedName}" = image.crop { inherit aspectRatio; }; }
        // foldAttrs (gravity: {
          "crop${normalizedName}${capitalize gravity}" = image.crop { inherit aspectRatio gravity; };
        }) gravities
      ) (lib.attrNames aspectRatios);

      # Generate grow functions for each aspect ratio and gravity combination
      generateGrowFunctions = foldAttrs (
        aspectRatio:
        let
          normalizedName = aspectRatios.${aspectRatio};
        in
        {
          "grow${normalizedName}" = image.grow { inherit aspectRatio; };
          "grow${normalizedName}'" = color: image.grow { inherit aspectRatio color; };
        }
        // foldAttrs (gravity: {
          "grow${normalizedName}${capitalize gravity}" = image.grow { inherit aspectRatio gravity; };
          "grow${normalizedName}${capitalize gravity}'" =
            color: image.grow { inherit aspectRatio gravity color; };
        }) gravities
      ) (lib.attrNames aspectRatios);

      # Generate growEdge functions for each aspect ratio and gravity combination
      generateGrowEdgeFunctions = foldAttrs (
        aspectRatio:
        let
          normalizedName = aspectRatios.${aspectRatio};
        in
        { "growEdge${normalizedName}" = image.growEdge { inherit aspectRatio; }; }
        // foldAttrs (gravity: {
          "growEdge${normalizedName}${capitalize gravity}" = image.growEdge { inherit aspectRatio gravity; };
        }) gravities
      ) (lib.attrNames aspectRatios);
    in
    rec {
      # transform:
      #   Apply arbitrary ImageMagick transformations to an image.
      #   Type: transform -> { args, ?nameSuffix, ?extension, ?preScript, ?extraAttrs } -> src -> Derivation
      transform =
        {
          args,
          nameSuffix ? "transformed",
          extension ? null,
          preScript ? "",
          extraAttrs ? { },
        }:
        src:
        let
          cleanFileName = getFileName src;
          baseName = removeExtension cleanFileName;

          fileNameParts = lib.splitString "." cleanFileName;
          defaultExtension = if lib.length fileNameParts > 1 then lib.last fileNameParts else "png";
          finalExtension = if extension != null then extension else defaultExtension;

          name = "${baseName}-${nameSuffix}.${finalExtension}";
        in
        pkgs.runCommand name
          (
            {
              buildInputs = [
                pkgs.imagemagick
                pkgs.jq
              ];
              __contentAddressed = true;
              allowSubstitutes = false;
              outputHashAlgo = "sha256";
              outputHashMode = "flat";
            }
            // extraAttrs
          )
          ''
            ${preScript}
            magick "${src}" ${args} -format ${finalExtension} +repage "$out"
          '';

      # crop:
      #   Crops an image to a specified aspect ratio using ImageMagick.
      #   Type: crop -> { aspectRatio, ?gravity } -> src -> Derivation
      crop =
        {
          aspectRatio,
          gravity ? "center",
        }:
        src:
        transform {
          args = "-gravity ${gravity} -crop \"${aspectRatio}\"";
          nameSuffix = "cropped-${aspectRatio}-${gravity}";
        } src;

      # Shared by grow/growEdge. Dimension detection and target-size math run
      # inside this same derivation (via preScript) instead of a separate
      # IFD build, so there's no eval-time readFile/fromJSON round-trip.
      # Type: growTransform -> { aspectRatio, gravity, nameSuffix, extraArgs } -> src -> Derivation
      growTransform =
        {
          aspectRatio,
          gravity,
          nameSuffix,
          extraArgs,
        }:
        src:
        let
          parts = lib.splitString ":" aspectRatio;
          aspectW = lib.toInt (lib.elemAt parts 0);
          aspectH = lib.toInt (lib.elemAt parts 1);
          resolutions = standardResolutions.${aspectRatio} or [ ];
        in
        transform {
          args = ''-resize "$finalWidth"x"$finalHeight" ${extraArgs} -gravity ${gravity} -extent "$finalWidth"x"$finalHeight"'';
          nameSuffix = "${nameSuffix}-${aspectRatio}-${gravity}";
          extraAttrs = {
            RESOLUTIONS_JSON = builtins.toJSON resolutions;
          };
          preScript = ''
            srcWidth=$(magick identify -format "%w" "${src}")
            srcHeight=$(magick identify -format "%h" "${src}")

            if (( srcWidth * ${toString aspectH} < srcHeight * ${toString aspectW} )); then
              targetWidth=$(( (srcHeight * ${toString aspectW} + ${toString aspectH} - 1) / ${toString aspectH} ))
              targetHeight=$srcHeight
            else
              targetWidth=$srcWidth
              targetHeight=$(( (srcWidth * ${toString aspectH} + ${toString aspectW} - 1) / ${toString aspectW} ))
            fi
            targetArea=$(( targetWidth * targetHeight ))

            finalDims=$(printf '%s' "$RESOLUTIONS_JSON" | jq -c \
              --argjson ta "$targetArea" --argjson tw "$targetWidth" --argjson th "$targetHeight" \
              'if length == 0 then {w: $tw, h: $th}
               else (map({w, h, diff: ((.w * .h - $ta) | if . < 0 then -. else . end)}) | sort_by(.diff) | .[0] | {w, h})
               end')
            finalWidth=$(printf '%s' "$finalDims" | jq -r .w)
            finalHeight=$(printf '%s' "$finalDims" | jq -r .h)
          '';
        } src;

      # growEdge:
      #   Expands an image to a specified aspect ratio by extending edge pixels (blur effect).
      #   Type: growEdge -> { aspectRatio, ?gravity } -> src -> Derivation
      growEdge =
        {
          aspectRatio,
          gravity ? "center",
        }:
        src:
        growTransform {
          inherit aspectRatio gravity;
          nameSuffix = "grown-edge";
          extraArgs = "-virtual-pixel edge";
        } src;

      # grow:
      #   Expands an image to a specified aspect ratio using ImageMagick, filling with a color.
      #   Type: grow -> { aspectRatio, ?gravity, ?color } -> src -> Derivation
      grow =
        {
          aspectRatio,
          gravity ? "center",
          color ? null,
        }:
        src:
        growTransform {
          inherit aspectRatio gravity;
          nameSuffix = "grown";
          extraArgs = "-background ${if color != null then "'${color}'" else "\"%[pixel:p{0,0}]\""}";
        } src;

      # removeBackground:
      #   Removes background from an image using flood fill at specified coordinates.
      #   Type: removeBackground -> { ?coordinates, ?fuzz } -> src -> Derivation
      removeBackground =
        {
          coordinates ? [ ],
          fuzz ? 10,
        }:
        src:
        let
          floodFillCommands =
            lib.concatMapStringsSep " "
              (coord: "-draw \"alpha ${toString coord.x},${toString coord.y} floodfill\"")
              (
                coordinates
                ++ [
                  {
                    x = 0;
                    y = 0;
                  }
                ]
              );
        in
        transform {
          args = "-alpha set -fuzz ${toString fuzz}% -fill none ${floodFillCommands}";
          nameSuffix = "no-bg";
          extension = "png";
        } src;

      # fillBackground:
      #   Fills transparent background with a solid color by flattening layers.
      #   Type: fillBackground -> { ?color } -> src -> Derivation
      fillBackground =
        {
          color ? "white",
        }:
        src:
        transform {
          args = "-background \"${color}\" -layers flatten";
          nameSuffix = "filled-bg";
        } src;

      cutHalf =
        gravity:
        transform {
          args = "-gravity ${gravity} -crop 100%x50%+0+0";
        };
    }
    // generateCropFunctions
    // generateGrowFunctions
    // generateGrowEdgeFunctions;

  # extractFrames':
  #   Extracts frames from a video file at specified timestamps with optional cropping.
  #   Type: extractFrames' -> videoFile -> timestamps -> { ?x, ?y, ?width, ?height } -> Derivation
  extractFrames' =
    videoFile: timestamps: cropOpts:
    let
      videoFileName = getFileName videoFile;

      cropFilter =
        if
          lib.isAttrs cropOpts && (cropOpts ? width || cropOpts ? height || cropOpts ? x || cropOpts ? y)
        then
          let
            w = toString (cropOpts.width or "");
            h = toString (cropOpts.height or "");
            x = toString (cropOpts.x or "");
            y = toString (cropOpts.y or "");
          in
          "-vf \"crop=${w}:${h}:${x}:${y}\""
        else
          "";

      # Extract each frame as a separate derivation
      extractSingleFrame =
        timestamp:
        let
          sanitizedTimestamp = lib.replaceStrings [ ":" "." ] [ "_" "_" ] timestamp;
        in
        pkgs.runCommand "${videoFileName}-${sanitizedTimestamp}.png"
          {
            buildInputs = [ pkgs.ffmpeg-headless ];
            __contentAddressed = true;
            allowSubstitutes = false;
            outputHashAlgo = "sha256";
            outputHashMode = "flat";
          }
          ''
            echo "Extracting frame at ${timestamp} of ${videoFile}"
            ffmpeg -i "${videoFile}" -ss ${timestamp} -update true -frames:v 1 ${cropFilter} $out
          '';

      frames = parallel (map extractSingleFrame) timestamps;
    in
    if lib.length frames == 1 then lib.head frames else frames;

  extractFrames = videoFile: timestamps: extractFrames' videoFile timestamps { };

  # toWebp:
  #   Converts a video file to an animated WebP file using ffmpeg.
  #   Type: toWebp -> src -> Derivation
  toWebp =
    src:
    let
      fullFileName = getFileName src;
      fileNameParts = lib.splitString "." fullFileName;
      baseName =
        if lib.length fileNameParts > 1 then
          lib.concatStringsSep "." (lib.init fileNameParts)
        else
          fullFileName;
      name = "${baseName}.webp";
    in
    pkgs.runCommand name
      {
        buildInputs = [ pkgs.ffmpeg-headless ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        ffmpeg -i "${src}" -vcodec libwebp -lossless 0 -compression_level 6 -q:v 50 -loop 0 -preset picture -an -vsync 0 $out
      '';
}
