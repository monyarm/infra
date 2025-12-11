{ config, ... }:
{
  getSecretPath = name: config.sops.secrets.${name}.path;
}
