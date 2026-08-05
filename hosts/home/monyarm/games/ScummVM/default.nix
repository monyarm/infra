{
  lib,
  pkgs,
  config,
  dirs,
  mkOutOfStoreSymlink,
  linkFiles,
  parallel,
  autoImport,
  ...
}:

with lib;

let
  languageMap = {
    # keep-sorted start
    "" = "";
    en = "English";
    jp = "Japanese";
    # Add other languages as needed
    # keep-sorted end
  };

  platformMap = {
    # keep-sorted start
    apple2 = "Apple II";
    pc = "DOS";
    windows = "Windows";
    # Add other platforms as needed
    # keep-sorted end
  };

  # Builds one scummvm.ini section (keyed by categoryId) from a game
  # definition. Shared by config.nix's hand-declared legacy entries and the
  # games.scummvm.games registry below, so a game's ini shape only lives in
  # one place.
  mkScummVMGame =
    {
      categoryId ? gameid,
      gameid ? engineid,
      engineid,
      description ? "", # Base description
      path ? "${dirs.Games}/ScummVM/${description}", # Path derived from base description
      platform ? "pc",
      extra ? "",
      guioptions ? "",
      language ? "en",
      ...
    }@args:
    assert (languageMap ? ${language} || language == "");
    let

      mappedPlatform = if (platform != "") then (platformMap.${platform} or null) else null;

      # Construct the bracketed part of the description
      # Only include parts if they are not empty
      bracketedParts = filter (s: s != "") [
        (if extra != "" then extra else "")
        (if mappedPlatform != null then mappedPlatform else "")
        (if language != "" then languageMap.${language} else "")
      ];

      # Combine bracketed parts into a single string, e.g., " (CD/DOS/English)"
      bracketedString =
        if bracketedParts != [ ] then " (" + (concatStringsSep "/" bracketedParts) + ")" else "";

      # Append the bracketed string to the base description
      finalDescription = "${description}${bracketedString}";

    in
    {
      "${categoryId}" = {
        inherit
          gameid
          engineid
          path
          platform
          extra
          language
          ;
        guioptions = "${guioptions}" + optionalString (language != "") "lang_${languageMap.${language}}";
        description = finalDescription;
      }
      // (removeAttrs args [
        "categoryId"
        "gameid"
        "description"
        "path"
        "engineid"
        "platform"
        "extra"
        "guioptions"
        "language"
      ]);
    };

  # A ScummVM target's categoryId (its scummvm.ini section header) is also
  # exactly what `scummvm <target>` expects on the command line, so it
  # doubles as the Steam launch argument.
  scummVMTargetId = g: g.categoryId or g.gameid or g.engineid;

in
{
  options.games.scummvm = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to fetch, optimize, and register ScummVM games at all.
        Disable to skip the whole (expensive, image-optimization-heavy)
        ScummVM build graph entirely, e.g. while setting up additional
        remote builders.
      '';
    };
    config = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Attrset fed directly into generators.toINI to produce scummvm.ini.";
    };
    firmware = mkOption {
      type = types.attrsOf (types.either types.package types.str);
      default = { };
      description = "Firmware/ROM files placed under ~/.local/share/scummvm/extra.";
    };
    games = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      description = ''
        Registry of ScummVM games declared once: each entry is fed straight
        to mkScummVMGame to produce its scummvm.ini section, and also
        registered as a programs.steam.games shortcut that launches
        `scummvm <target>` directly. Set `name` to override the Steam
        shortcut's display name (defaults to `description`). Set
        `steamAppId` (and `steamCdnImagesHash`, for artwork) when the game
        is actually owned on Steam, so it patches that real app's
        LaunchOptions instead of becoming a synthetic non-Steam shortcut;
        both are stripped before generating the scummvm.ini section.
      '';
    };
  };

  imports = [
    # keep-sorted start
    ./config.nix
    ./firmware.nix
    # keep-sorted end
  ]
  ++ autoImport ./games;

  config = {
    _module.args = { inherit mkScummVMGame; };

    games.scummvm.config = builtins.foldl' lib.recursiveUpdate { } (
      map (
        g:
        mkScummVMGame (
          removeAttrs g [
            "steamAppId"
            "steamCdnImagesHash"
          ]
        )
      ) (lib.attrValues config.games.scummvm.games)
    );

    programs.steam.games = lib.mapAttrs' (
      _: g:
      lib.nameValuePair (scummVMTargetId g) (
        {
          name = g.name or g.description;
          game = scummVMTargetId g;
          launcher.package = pkgs.scummvm;
        }
        // lib.optionalAttrs (g ? steamAppId) { inherit (g) steamAppId; }
        // lib.optionalAttrs (g ? steamCdnImagesHash) { inherit (g) steamCdnImagesHash; }
      )
    ) config.games.scummvm.games;

    xdg.configFile."scummvm/scummvm.ini".text = generators.toINI { } config.games.scummvm.config;
    xdg.dataFile =
      (parallel (linkFiles "scummvm/extra") (lib.attrValues config.games.scummvm.firmware))
      // {
        "scummvm/saves".source = mkOutOfStoreSymlink "${dirs.hmConfig}/ScummVM/.local/share/scummvm/saves";
      };
  };
}
