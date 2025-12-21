{
  pkgs,
  lib,
  ...
}:
rec {
  # getImageDimensions:
  #   Gets the width and height of an image using ImageMagick.
  #   Type: getImageDimensions -> src -> { width, height }
  getImageDimensions =
    src:
    let
      dimensionsJson =
        pkgs.runCommand "image-dimensions.json"
          {
            buildInputs = [
              pkgs.imagemagick
              pkgs.jq
            ];
          }
          ''
            width=$(magick identify -format "%w" ${src})
            height=$(magick identify -format "%h" ${src})
            jq -n --arg w "$width" --arg h "$height" '{width: ($w | tonumber), height: ($h | tonumber)}' > $out
          '';
      dimensions = builtins.fromJSON (builtins.readFile dimensionsJson);
    in
    dimensions;

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
      generateCropFunctions = lib.foldl' (
        acc: aspectRatio:
        let
          normalizedName = aspectRatios.${aspectRatio};
          # Generate cropAspectRatio function (e.g., crop16x9)
          cropFunc = {
            "crop${normalizedName}" = image.crop { inherit aspectRatio; };
          };
          # Generate cropAspectRatioGravity functions (e.g., crop16x9South)
          gravityFuncs = lib.foldl' (
            innerAcc: gravity:
            let
              capitalizedGravity =
                lib.toUpper (lib.substring 0 1 gravity) + lib.substring 1 (lib.stringLength gravity) gravity;
              funcName = "crop${normalizedName}${capitalizedGravity}";
            in
            innerAcc // { ${funcName} = image.crop { inherit aspectRatio gravity; }; }
          ) { } gravities;
        in
        acc // cropFunc // gravityFuncs
      ) { } (lib.attrNames aspectRatios);

      # Generate grow functions for each aspect ratio and gravity combination
      generateGrowFunctions = lib.foldl' (
        acc: aspectRatio:
        let
          normalizedName = aspectRatios.${aspectRatio};
          # Generate growAspectRatio function (e.g., grow16x9)
          growFunc = {
            "grow${normalizedName}" = image.grow { inherit aspectRatio; };
          };
          # Generate growAspectRatio' function with color parameter (e.g., grow16x9')
          growFuncPrime = {
            "grow${normalizedName}'" = color: image.grow { inherit aspectRatio color; };
          };
          # Generate growAspectRatioGravity functions (e.g., grow16x9South)
          gravityFuncs = lib.foldl' (
            innerAcc: gravity:
            let
              capitalizedGravity =
                lib.toUpper (lib.substring 0 1 gravity) + lib.substring 1 (lib.stringLength gravity) gravity;
              funcName = "grow${normalizedName}${capitalizedGravity}";
              funcNamePrime = "grow${normalizedName}${capitalizedGravity}'";
            in
            innerAcc
            // {
              ${funcName} = image.grow { inherit aspectRatio gravity; };
            }
            // {
              ${funcNamePrime} = color: image.grow { inherit aspectRatio gravity color; };
            }
          ) { } gravities;
        in
        acc // growFunc // growFuncPrime // gravityFuncs
      ) { } (lib.attrNames aspectRatios);
    in
    rec {
      # transform:
      #   Apply arbitrary ImageMagick transformations to an image.
      #   Type: transform -> { args, ?nameSuffix, ?extension } -> src -> Derivation
      transform =
        {
          args,
          nameSuffix ? "transformed",
          extension ? null,
        }:
        src:
        let
          fullFileName = lib.getName src;
          fileNameParts = lib.splitString "." fullFileName;
          baseName =
            if lib.length fileNameParts > 1 then
              lib.concatStringsSep "." (lib.init fileNameParts)
            else
              fullFileName;
          defaultExtension = if lib.length fileNameParts > 1 then lib.last fileNameParts else "png";
          finalExtension = if extension != null then extension else defaultExtension;

          name = "${baseName}-${nameSuffix}.${finalExtension}";
        in
        pkgs.runCommand name
          {
            buildInputs = [ pkgs.imagemagick ];
          }
          ''
            magick ${src} ${args} -format ${finalExtension} +repage $out
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
        let
          # Parse aspect ratio "W:H" into separate parts
          parts = lib.splitString ":" aspectRatio;
          aspectW = lib.toInt (lib.elemAt parts 0);
          aspectH = lib.toInt (lib.elemAt parts 1);

          # Get source image dimensions
          dims = getImageDimensions src;
          srcWidth = dims.width;
          srcHeight = dims.height;

          # Calculate source and target ratios
          srcRatio = srcWidth / srcHeight;
          targetRatio = aspectW / aspectH;

          # Calculate what dimensions would be needed to grow to aspect ratio
          targetWidth =
            if srcRatio < targetRatio then builtins.ceil (srcHeight * aspectW / aspectH) else srcWidth;

          targetHeight =
            if srcRatio < targetRatio then srcHeight else builtins.ceil (srcWidth * aspectH / aspectW);

          targetArea = targetWidth * targetHeight;

          # Define standard resolutions for common aspect ratios
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

          resolutions = standardResolutions.${aspectRatio} or [ ];

          # Find closest standard resolution by area difference
          findClosest =
            resolutions:
            if resolutions == [ ] then
              {
                w = targetWidth;
                h = targetHeight;
              }
            else
              let
                calcDiff =
                  res:
                  let
                    resArea = res.w * res.h;
                  in
                  if resArea > targetArea then resArea - targetArea else targetArea - resArea;

                withDiffs = map (res: {
                  inherit res;
                  diff = calcDiff res;
                }) resolutions;
                sorted = lib.sort (a: b: a.diff < b.diff) withDiffs;
                closest = (lib.head sorted).res;
              in
              closest;

          finalDims = findClosest resolutions;
          finalWidth = finalDims.w;
          finalHeight = finalDims.h;
        in
        transform {
          args = lib.concatStringsSep " " [
            "-resize \"${toString finalWidth}x${toString finalHeight}\""
            "-background ${if color != null then "'${color}'" else "\"%[pixel:p{0,0}]\""}"
            "-gravity ${gravity}"
            "-extent \"${toString finalWidth}x${toString finalHeight}\""
          ];
          nameSuffix = "grown-${aspectRatio}-${gravity}";
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
    }
    // generateCropFunctions
    // generateGrowFunctions;

  # extractFrames':
  #   Extracts frames from a video file at specified timestamps with optional cropping.
  #   Type: extractFrames' -> videoFile -> timestamps -> { ?x, ?y, ?width, ?height } -> Derivation
  extractFrames' =
    videoFile: timestamps: cropOpts:
    let
      videoFileName = builtins.baseNameOf (builtins.unsafeDiscardStringContext videoFile);
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
          }
          ''
            echo "Extracting frame at ${timestamp} of ${videoFile}"
            ffmpeg -i ${videoFile} -ss ${timestamp} -frames:v 1 ${cropFilter} $out
          '';

      frames = map extractSingleFrame timestamps;
    in
    if lib.length frames == 1 then
      # Single frame, return it directly
      lib.head frames
    else
      # Multiple frames, create a directory with named symlinks
      pkgs.linkFarm "${videoFileName}-frames" (
        map (frame: {
          inherit (frame) name;
          path = frame;
        }) frames
      );

  extractFrames = videoFile: timestamps: extractFrames' videoFile timestamps { };

  # toWebp:
  #   Converts a video file to an animated WebP file using ffmpeg.
  #   Type: toWebp -> src -> Derivation
  toWebp =
    src:
    let
      fullFileName = lib.getName src;
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
      }
      ''
        ffmpeg -i ${src} -vcodec libwebp -lossless 0 -compression_level 6 -q:v 50 -loop 0 -preset picture -an -vsync 0 $out
      '';
}
