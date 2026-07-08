{
  pkgs,
  system,
  ...
}:

let
  detectGpuScript = pkgs.writeShellScript "detect-gpu-script" ''
    lspci_cmd="${pkgs.pciutils}/bin/lspci"
    grep_cmd="${pkgs.gnugrep}/bin/grep"

    GPU_TYPE="other"
    if "$lspci_cmd" | "$grep_cmd" -i nvidia > /dev/null; then
      GPU_TYPE="nvidia"
    elif "$lspci_cmd" | "$grep_cmd" -i intel > /dev/null; then
      GPU_TYPE="intel"
    elif "$lspci_cmd" | "$grep_cmd" -i amd > /dev/null; then
      GPU_TYPE="amd"
    fi
    echo "\"$GPU_TYPE\""
  '';

  detectDeviceTypeScript = pkgs.writeShellScript "detect-device-type-script" ''
    DEVICE_TYPE="desktop" # Default to desktop
    if [ -f /system/build.prop ]; then
      DEVICE_TYPE="android-phone"
    elif ls /sys/class/power_supply/BAT* > /dev/null 2>&1; then
      DEVICE_TYPE="laptop"
    fi
    echo "\"$DEVICE_TYPE\""
  '';
in
{
  inherit system;

  gpu = builtins.exec [
    detectGpuScript
  ];

  deviceType = builtins.exec [
    detectDeviceTypeScript
  ];
}
