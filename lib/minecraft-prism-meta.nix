{
  pkgs,
  lib,
  ...
}:
rec {
  # "group:artifact:version[:classifier]" -> the Maven-layout relative path
  # PrismLauncher's shared libraries/ cache and Mojang's own library
  # downloads both use.
  mavenCoordToPath =
    coord:
    let
      parts = lib.splitString ":" coord;
      group = builtins.elemAt parts 0;
      artifact = builtins.elemAt parts 1;
      version = builtins.elemAt parts 2;
      classifier = if builtins.length parts > 3 then "-" + builtins.elemAt parts 3 else "";
      groupPath = lib.concatStringsSep "/" (lib.splitString "." group);
    in
    "${groupPath}/${artifact}/${version}/${artifact}-${version}${classifier}.jar";

  # Fetches every (already platform-filtered, already hash-pinned) library
  # in a prism-component's sources.nix record, individually, no discovery.
  mkPrismComponentLibraries =
    componentRecord:
    map (l: {
      path = mavenCoordToPath l.name;
      drv = pkgs.fetchurl {
        inherit (l) url;
        inherit (l) hash;
      };
    }) componentRecord.libraries;

  # Regenerates a patches/<uid>.json equivalent to what PrismLauncher itself
  # would cache after resolving this component online -- functionally
  # equivalent JSON, not required to be byte-identical to the original.
  mkPrismComponentPatch =
    componentRecord:
    builtins.toJSON (
      {
        inherit (componentRecord) name;
        inherit (componentRecord) uid;
        inherit (componentRecord) version;
        formatVersion = 1;
        libraries = map (l: {
          inherit (l) name;
          downloads.artifact.url = l.url;
        }) componentRecord.libraries;
      }
      // lib.optionalAttrs (componentRecord.mainClass != null) {
        inherit (componentRecord) mainClass;
      }
      // lib.optionalAttrs (componentRecord.mainJar != null) {
        mainJar = {
          name = componentRecord.mainJar.name;
          downloads.artifact.url = componentRecord.mainJar.url;
        };
      }
      // lib.optionalAttrs (componentRecord.requires != [ ]) {
        inherit (componentRecord) requires;
      }
      // lib.optionalAttrs (componentRecord.assetIndex != null) {
        assetIndex = {
          id = componentRecord.assetIndex.id;
          url = componentRecord.assetIndex.url;
        };
      }
    );

  # The mmc-pack.json component entry for this uid/version.
  mkMmcPackComponent =
    componentRecord:
    {
      inherit (componentRecord) uid;
      inherit (componentRecord) version;
      cachedName = componentRecord.name;
      cachedVersion = componentRecord.version;
    }
    // lib.optionalAttrs (componentRecord.requires != [ ]) {
      cachedRequires = componentRecord.requires;
    };
}
