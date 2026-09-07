{
  pkgs,
  lib,
  fetchModrinth,
  mkModDir,
  ...
}:
{
  # Assembles a Modrinth .mrpack's full file tree: the archive itself (for
  # its overrides/) plus every listed file, each fetched individually with
  # the hash already published in modrinth.index.json (and already copied
  # into sources.nix's `files` list by process_modrinth_modpack) -- no
  # assembled-tree hash discovery needed anywhere.
  mkModrinthPackTree =
    { project, versionRecord }:
    let
      archive = fetchModrinth {
        inherit project;
        inherit (versionRecord) versionId;
        filename = versionRecord.archiveFilename;
        sha256 = versionRecord.archiveHash; # SRI string, algo inferred from prefix
      };
      extracted = pkgs.runCommand "modrinth-pack-${project}-extracted" { } ''
        mkdir -p "$out"
        ${pkgs.unzip}/bin/unzip -q "${archive}" -d "$out"
      '';
      fetchedFiles = map (f: {
        inherit (f) path;
        drv = pkgs.fetchurl {
          inherit (f) url;
          inherit (f) hash;
        };
      }) versionRecord.files;
      filesLayer = pkgs.runCommand "modrinth-pack-${project}-files" { } ''
        mkdir -p "$out"
        ${lib.concatMapStringsSep "\n" (f: ''
          mkdir -p "$out/$(dirname "${f.path}")"
          cp "${f.drv}" "$out/${f.path}"
        '') fetchedFiles}
      '';
    in
    mkModDir {
      name = "modrinth-pack-${project}";
      layers = [
        "${extracted}/overrides"
        filesLayer
      ];
    };
}
