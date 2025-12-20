{
  lib,
  dirs,
  shouldFullUpdate,
  ...
}:

let
  desiredFlatpaks = [
    # keep-sorted start
    "com.github.tchx84.Flatseal"
    "com.steamgriddb.SGDBoop"
    "com.usebottles.bottles"
    #    "io.github.softfever.OrcaSlicer" package is missing
    "net.davidotek.pupgui2"
    "org.libretro.RetroArch"
    # keep-sorted end
  ];
in
{
  home.activation.flatpakManagement = lib.mkIf shouldFullUpdate (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
       # Set PATH for flatpak_program_manager.sh
       export PATH=${builtins.getEnv "PATH"}

      # 1. Ensure the Flathub repo is added
      ${dirs.scripts}/package-managers/flatpak_remote_manager.sh "flathub" "https://flathub.org/repo/flathub.flatpakrepo"

      # 1.1. Ensure the Flathub Beta repo is added
      ${dirs.scripts}/package-managers/flatpak_remote_manager.sh "flathub-beta" "https://flathub.org/beta-repo/flathub-beta.flatpakrepo"

       # 2. Get currently installed Flatpaks
       installedFlatpaks=$(sudo /usr/bin/flatpak list --app --columns=application)

       # 3. Remove any Flatpaks that are NOT in the desired list
       for installed in $installedFlatpaks; do
         if ! echo ${toString desiredFlatpaks} | grep -q $installed; then
           echo -ne "\r\033[K\t\033[35m$installed\033[0m:\tRemoving because it's not in the desiredFlatpaks list.\n"
           sudo /usr/bin/flatpak uninstall -y --noninteractive $installed &> /dev/null || true
         fi
       done

      #  4. Install or re-install the Flatpaks you DO want, and update all
      ${lib.concatStringsSep "\n" (
        lib.map (flatpak: ''
          ${dirs.scripts}/package-managers/flatpak_program_manager.sh "${flatpak}" || true
        '') desiredFlatpaks
      )}

       # 5. Remove unused Flatpaks
       sudo /usr/bin/flatpak uninstall --unused -y &> /dev/null || true

    ''
  );
}
