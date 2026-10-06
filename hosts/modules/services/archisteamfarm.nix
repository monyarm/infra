# ArchiSteamFarm bot "cards" (SteamGuard card farming).
#
# Existing bot state is migrated in from ~/asf-config into the module's
# default dataDir (/var/lib/archisteamfarm) -- see .opencode/plans/
# nix-profile-migration.md phase 1d. The service is headless and runs as the
# built-in system user, which is why the password lives in a sops secret
# rather than LocalSettings-style config.
#
# passwordFile -> the module emits PasswordFormat = 4 (ECryptoMethod.File), so
# ASF reads the password from the path at runtime. preStart substitutes the
# secret's *contents* into the generated config, so plaintext never lands in
# the store. Verified that switching PasswordFormat 0 -> 4 does NOT re-encrypt
# the existing tokens in cards.db (ArchiCryptoHelper.Encrypt is a no-op for
# File, HasTransformation(File) is false), so no re-login / 2FA re-prompt.
{ config, ... }:
{
  services.archisteamfarm = {
    enable = true;

    # Miniature Compendium
    settings.SteamOwnerID = 76561198033006574;

    bots.cards = {
      username = "monyarm";
      passwordFile = config.sops.secrets.archisteamfarm_password.path;
    };
  };
}
