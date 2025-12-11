{
  config,
  lib,
  mkOutOfStoreSymlink,
  ...
}:

let
  commonAccountProps = {
    eligibleForMigration = true;
    hasMultipleProfiles = false;
    legacy = false;
    persistent = true;
    type = "Mojang";
    userProperites = [ ];
  };

  launcherAccounts = rec {
    accounts = lib.listToAttrs (
      lib.map
        (acc: {
          name = acc.localId;
          value = commonAccountProps // acc;
        })
        [
          {
            accessToken = "";
            localId = "2893248bd49140559e02f26738eba70e";
            minecraftProfile = {
              id = "98c839f520e74ce2acd4deebc20c7b10";
              name = "monyarm1";
            };
            remoteId = "620af47b9e45475981c1fe438c666474";
            username = "monyarm@gmail.com";
          }
        ]
    );
    activeAccountLocalId = (builtins.head (builtins.attrValues accounts)).localId;
    inherit (config.sops.placeholder) mojangClientToken;
  };
in
{
  sops.templates = {
    "launcher_accounts.json".content = builtins.toJSON launcherAccounts;
  };
  home.file = {
    ".minecraft/launcher_accounts.json".source =
      mkOutOfStoreSymlink
        config.sops.templates."launcher_accounts.json".path;
  };
}
