{
  config,
  pkgs,
  ...
}:
{
  getSecretPath = name: config.sops.secrets."${name}".path;

  # Impurely decode and import a sops-encoded nix file at evaluation time
  importSopsNix =
    file:
    builtins.exec [
      "${pkgs.sops}/bin/sops"
      "--decrypt"
      (toString file)
    ];
}
