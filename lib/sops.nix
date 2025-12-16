{
  config,
  pkgs,
  ...
}:
{
  getSecretPath = name: config.sops.secrets."${name}".path;

  # Impurely decode and import a sops-encoded nix file at evaluation time
  # This uses builtins.exec which is impure and executes at eval time
  # Usage: importSopsNix ./secrets.nix
  importSopsNix =
    file:
    let
      # Use builtins.exec to decrypt at evaluation time
      decryptedContent = builtins.exec [
        "${pkgs.sops}/bin/sops"
        "--decrypt"
        (toString file)
      ];
    in
    # Write decrypted content to store and import it
    import (builtins.toFile "decrypted-${baseNameOf (toString file)}" decryptedContent);
}
