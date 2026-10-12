# `psp.files`, modelled on Home Manager's fileType. `owner` is an addition:
# manifest attribution only, never a FAT32 permission.
{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkIf
    mkOption
    types
    ;

  # Destination keys contain "/" which Nix forbids in store names. Same
  # approach as Home Manager's lib.strings.storeFileName: replace unsafe
  # characters with "_" rather than deriving from the basename.
  storeName =
    name:
    let
      safe = builtins.filter (c: builtins.match "[a-zA-Z0-9.+_=]" c != null) (
        lib.stringToCharacters name
      );
      collapsed = lib.foldl' (acc: c: if c == "_" && lib.hasSuffix "_" acc then acc else acc + c) "" safe;
    in
    if collapsed == "" then "console-file" else collapsed;
in
{
  options.psp.files = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to include this file in the generated generation.";
            };

            text = mkOption {
              type = types.nullOr types.lines;
              default = null;
              description = ''
                Literal file content. Mutually exclusive with an explicit
                `source`; when set, `source` is synthesized from this text.
              '';
            };

            source = mkOption {
              type = types.nullOr types.path;
              # Reached only when neither text nor source was supplied, so this
              # throws on access at evaluation time rather than at build time.
              default = throw "console: psp.files.${name} must set either 'text' or 'source'";
              description = ''
                Path or derivation supplying the file or directory content.
                Directory sources are expanded only when `recursive` is true.
              '';
            };

            recursive = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Expand a directory `source` recursively. Expansion happens at
                build time; symlinks and non-regular files are rejected.
              '';
            };

            owner = mkOption {
              type = types.str;
              default = "";
              example = "homebrew.pspfiler";
              description = ''
                Logical resource that owns this file, used for manifest
                attribution and size reporting only. FAT32 has no POSIX
                ownership and none is implied here.
              '';
            };
          };

          config.source = mkIf (config.text != null) (
            mkDefault (
              pkgs.writeTextFile {
                name = storeName name;
                inherit (config) text;
                # Marks the synthesized source so assertions can tell "only
                # text was set" apart from "text and an explicit source".
                passthru.consoleSynthesized = true;
              }
            )
          );
        }
      )
    );
    default = { };
    description = ''
      Files to place on the memory card, keyed by card-relative destination
      path. Destination paths must be strict relative POSIX paths and may not
      collide with one another or with the reserved `.psp-nix/` directory.
    '';
  };

  config.assertions =
    let
      # Both-set means: text was given AND the source was not synthesized from
      # it. A null source means text/source was never set at all; that case is
      # already reported by the source default, so exclude it here.
      bothSet = lib.filter (e: e.text != null && e.source != null && !(e.source ? consoleSynthesized)) (
        lib.attrValues config.psp.files
      );
      names = lib.map (e: e.source.name or "<unknown>") bothSet;
    in
    [
      {
        assertion = bothSet == [ ];
        message = ''
          console: these psp.files entries set both 'text' and 'source':
          ${lib.concatStringsSep ", " names}
          Set exactly one.
        '';
      }
    ];
}
