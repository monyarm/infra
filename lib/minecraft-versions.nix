{ lib, ... }:
{
  # selector: "<versionKey>" | "latest" | "latestMajor" | "latestIKnowWhatImDoing"
  #           each optionally suffixed ":<loaderOverride>", e.g. "latest:quilt"
  pickModVersion =
    {
      modTable,
      selector,
      minecraftVersion,
      loader,
    }:
    let
      parts = lib.splitString ":" selector;
      tier = builtins.elemAt parts 0;
      effectiveLoader = if builtins.length parts > 1 then builtins.elemAt parts 1 else loader;

      majorMinor = v: lib.concatStringsSep "." (lib.take 2 (lib.splitString "." v));

      loaderOk = entry: builtins.elem effectiveLoader entry.loaders;
      exactOk = entry: builtins.elem minecraftVersion entry.gameVersions;
      majorOk = entry: builtins.any (gv: majorMinor gv == majorMinor minecraftVersion) entry.gameVersions;

      candidates =
        if tier == "latest" then
          lib.filterAttrs (_: e: loaderOk e && exactOk e) modTable
        else if tier == "latestMajor" then
          lib.filterAttrs (_: e: loaderOk e && majorOk e) modTable
        else if tier == "latestIKnowWhatImDoing" then
          lib.filterAttrs (_: loaderOk) modTable
        else
          null; # explicit versionKey, handled below

      newest =
        attrs:
        if attrs == { } then
          throw "pickModVersion: no version matched selector ${selector} for minecraftVersion ${minecraftVersion}/${effectiveLoader}"
        else
          (lib.foldlAttrs (
            best: _: e:
            if best == null || e.date > best.date then e else best
          ) null attrs).package;
    in
    if candidates != null then
      newest candidates
    else
      (modTable.${tier} or (throw "pickModVersion: no version '${tier}' in table")).package;
}
