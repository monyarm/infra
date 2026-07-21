{
  pkgs,
  lib,
  ...
}:
{
  buildDosBox =
    {
      pname,
      version,
      # Overridable DOSBox package, defaulting to staging
      dosbox ? pkgs.dosbox-staging,
      # Attribute set of mounts: e.g., { D = ./Doom.img; E =
      # ./CdFiles; }
      mounts ? { },
      # Custom DOSBox environment variables
      dosboxEnv ? { },
      # The DOS script / commands run inside DOSBox
      dosboxScript ? "",
      # Standard post-processing Bash commands
      buildPhase ? "",
      # Extra build inputs
      nativeBuildInputs ? [ ],
      ...
    }@args:
    let
      # Assert that drive C is not manually passed in the mounts set
      hasExplicitCMount = lib.any (name: lib.toLower name == "c") (lib.attrNames mounts);
      assertionChecked = lib.assertMsg (!hasExplicitCMount) ''
        [dosbox-derivation]: Drive 'c' is reserved and automatically 
        mounted to the Nix build directory. Do not manually define 
        "C" or "c" in your mounts attribute set.
      '';
    in
    assert assertionChecked;
    pkgs.stdenv.mkDerivation (
      lib.recursiveUpdate
        (removeAttrs args [
          "dosbox"
          "mounts"
          "dosboxEnv"
          "dosboxScript"
          "buildPhase"
        ])
        {
          inherit pname version;
          nativeBuildInputs = [
            dosbox
            pkgs.xvfb-run
          ]
          ++ nativeBuildInputs;
          # Define the custom phase sequence
          phases = [
            "unpackPhase"
            "dosboxPhase"
            "buildPhase"
            "installPhase"
          ];
          passAsFile = [ "dosboxConfig" ];
          dosboxConfig = ''
            [sdl] fullscreen=false windowresolution=640x480 
            output=surface [cpu] core=auto cputype=auto cycles=max 
            [autoexec]
            # 1. Mount the host execution directory as C: and move into 
            # it
            mount c . c:
            # 2. Dynamically generate other user-specified mounts
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                letter: path:
                let
                  isDir = lib.filesystem.pathType path == "directory";
                  drive = lib.toLower letter;
                in
                if isDir then "mount ${drive} ${path}" else "imgmount 
        ${drive} ${path}"
              ) mounts
            )}
            # 3. Execute the user's custom DOS script
            ${dosboxScript}
            # 4. Terminate DOSBox safely to return control to Nix
            exit '';
          # Phase 1: Run your DOS script headlessly
          dosboxPhase = ''
            runHook preDosbox echo "=== Starting Headless 
               DOSBox Phase ==="
               # Export specified DOSBox environment variables to Bash
               ${lib.concatStringsSep "\n" (
                 lib.mapAttrsToList (name: val: "export ${name}=\"${val}\"") dosboxEnv
               )}
               # Ensure headless execution
               export SDL_VIDEODRIVER=dummy export SDL_AUDIODRIVER=dummy
               # Run DOSBox directly utilizing our generated configuration 
               # file
               xvfb-run -a dosbox -conf "$dosboxConfigPath" echo "=== 
               Headless DOSBox Phase Completed ===" runHook postDosbox
          '';
          # Phase 2: Post-processing Bash phase
          buildPhase = ''
            runHook preBuild
               
               echo "=== Starting Bash Build Phase ===" ${buildPhase} echo 
               "=== Bash Build Phase Completed ===" runHook postBuild
          '';
          installPhase = ''
            runHook preInstall if [ -d "out" ] && [ 
               ! -e "$out" ]; then
                 cp -r out $out elif [ ! -e "$out" ]; then mkdir -p $out fi 
               runHook postInstall
          '';
        }
    );
}
