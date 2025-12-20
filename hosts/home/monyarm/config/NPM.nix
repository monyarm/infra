{
  lib,
  dirs,
  shouldFullUpdate,
  ...
}:

let
  desiredNPMGlobalPackages = [
    # keep-sorted start
    "@google/gemini-cli@nightly"
    "fetch-fic"
    "npm"
    # keep-sorted end
  ];
in
{
  home.file.".npmrc".text = "prefix=~/.npm-global";

  home.activation.npmGlobalManagement = lib.mkIf shouldFullUpdate (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      # Set PATH for npm_program_manager.sh
      export PATH=${builtins.getEnv "PATH"}

      # 1. Get currently installed global NPM packages
      installedNPMGlobalPackages=$(npm list -g --depth=0 --json | jq -r '.dependencies | keys[]')

      # 2. Remove any global NPM packages that are NOT in the desired list
      for installed in $installedNPMGlobalPackages; do
        foundInDesired=false
        for desired in ${toString desiredNPMGlobalPackages}; do
          # Extract the base package name from the desired package (e.g., "@google/gemini-cli")
          desiredBaseName=$(echo $desired | sed -E 's/(@?[^@]+)@?.*/\1/')
          if [ "$installed" = "$desiredBaseName" ]; then
            foundInDesired=true
            break
          fi
        done
        if [ "$foundInDesired" = "false" ]; then
          echo -ne "\r\033[K\033[35m$installed\033[0m:\tRemoving because it's not in the desiredNPMGlobalPackages list.\n"
          npm uninstall -g $installed &> /dev/null || true
        fi
      done

      # 3. Install or re-install the global NPM packages you DO want
      for pkg in ${toString desiredNPMGlobalPackages}; do
        ${dirs.scripts}/package-managers/npm_program_manager.sh "$pkg"
      done
    ''
  );
}
