{
  lib,
  dirs,
  shouldFullUpdate,
  ...
}:

let
  desiredCargoPackages = [
    # keep-sorted start
    "binwalk"
    "bsatool_rs"
    "cargo-cache"
    "cargo-generate"
    "diskus"
    "oxyromon"
    # keep-sorted end
  ];
in
{
  home.activation.cargoManagement = lib.mkIf shouldFullUpdate (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      export PATH=${builtins.getEnv "PATH"};

      # 1. Get currently installed Cargo packages
      installedCargoPackages=$(cargo install --list | grep -E '^[a-zA-Z0-9_-]+ v[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $1}')

      # 2. Remove any Cargo packages that are NOT in the desired list
      for installed in $installedCargoPackages; do
        if ! echo ${toString desiredCargoPackages} | grep -q $installed; then
          echo -ne "\r\033[K\033[35m$installed\033[0m:\tRemoving because it's not in the desiredCargoPackages list.\n"
          cargo uninstall -y $installed &> /dev/null || true
        fi
      done

      # 3. Install or re-install the Cargo packages you DO want
      for pkg in ${toString desiredCargoPackages}; do
        ${dirs.lib}/cargo_program_manager.sh "$pkg"
      done
    ''
  );
}
