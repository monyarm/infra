{ lib, dirs, ... }:

let
  # Function to generate the entire PresetMachines attribute set
  generatePresetMachines =
    machineName: filamentList:
    let
      encodedMachineName = lib.strings.escapeURL machineName;
      # Append _0.4 AFTER encoding
      finalEncodedMachineName = "${encodedMachineName}_0.4";
      # Generate the individual material entries
      materialEntries = lib.listToAttrs (
        lib.imap0 (
          _index: filamentType:
          let
            key = "${finalEncodedMachineName}\Extruders\0\PresetMaterials\${toString (index + 1)}\name";
          in
          {
            name = key;
            value = filamentType;
          }
        ) filamentList
      );
    in
    materialEntries
    // {
      size = lib.length filamentList;
      machine_curren_index = 0;
    };

  crealityPrintLocalShare = "${dirs.HOME}/.local/share/Creality/Creality Print/4.3";
in
{
  xdg.configFile."Creality/Creality Print.conf".text = lib.generators.toINI { } {
    General = {
      AutoCheckForUpdates = true;
      dialogLastPath = "${dirs.HOME}/Downloads";
    };

    AutoSave_Path = {
      filePath = "${crealityPrintLocalShare}//tmpProject/default.cxprj";
    };

    Creality3DrecentFiles = {
      fileList = "${crealityPrintLocalShare}/Slice/temp.gcode";
      numOfRecentFiles = 10;
    };

    Creality3DrecentProject = {
      fileList = "@Invalid()";
      numOfRecentFiles = 10;
    };

    PresetMachines = generatePresetMachines "Ender-3 V3 KE" [
      # keep-sorted start
      "CR-ABS_1.75"
      "CR-PETG_1.75"
      "CR-PLA_1.75"
      "Generic-ASA_1.75"
      "HP-TPU_1.75"
      "Hyper PLA_1.75"
      # keep-sorted end
    ];

    cloud_service = {
      server_type = 1;
    };

    language_perfer_config = {
      language_type = "en.ts";
    };

    profile_setting = {
      first_start = 1;
    };

    themecolor_config = {
      themecolor_config = 0;
    };
  };
}
