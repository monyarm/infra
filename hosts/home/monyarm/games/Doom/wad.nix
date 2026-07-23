{
  pkgs,
  lib,
  config,
  getFile,
  autoImport,
  ...
}:
let

  mkDoom =
    {
      iwad,
      wad ? [ ],
      ...
    }@args:
    (lib.removeAttrs args [
      "wad"
      "iwad"
    ])
    // {
      game = iwad;
      launcher = {
        package = pkgs.uzdoom;
        args = [ "-iwad" ];
      };
      args = [ "-file" ]
      ++ (lib.optionals (wad != null && wad != [ ]) (map (x: "${x}") wad))
      ++ [ "${config.games.doom.wads.lights}" ];
    };

  wadFilter = [ "regex:(.*\.(wad|WAD))" ];

  # itch (and similar) uploads get re-fetched whenever the author ships a new
  # version, and the exact filename can change between releases (e.g. a
  # version number baked into the name); rather than hardcode it, pick it out
  # of a file list (as recorded in sources.nix) by extension instead.
  findWad =
    files:
    lib.findFirst (f: lib.any (ext: lib.hasSuffix ext f) [
      ".pk3"
      ".ipk3"
      ".wad"
      ".iwad"
    ]) (throw "no wad/pk3-like file found in ${toString files}") files;

in
{
  options.games.doom.wads = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = ''
      Registry of Doom WAD/PK3 derivations.
    '';
  };

  imports = autoImport ./wad;

  config = {
    _module.args = { inherit mkDoom wadFilter findWad; };

    games.doom.wads.lights = pkgs.uzdoom |> getFile "share/games/uzdoom/lights.pk3";
  };
}
