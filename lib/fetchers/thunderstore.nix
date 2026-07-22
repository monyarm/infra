{
  fetchzipNoSubst,
  ...
}:
{
  fetchThunderstore =
    {
      namespace,
      name,
      version,
      hash,
    }:
    fetchzipNoSubst {
      name = "${namespace}-${name}-${version}";
      url = "https://thunderstore.io/package/download/${namespace}/${name}/${version}/";
      extension = "zip";
      # Thunderstore packages are a flat list of files (manifest.json, icon.png,
      # plugin dll, ...) rather than a single wrapping directory.
      stripRoot = false;
      inherit hash;
    };
}
