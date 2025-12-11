{
  pkgs,
  system,
  ...
}:

let
  detectGpuScript = pkgs.writeShellScript "detect-gpu-script" ''
    GPU_TYPE="other"
    if lspci | grep -i nvidia > /dev/null; then
      GPU_TYPE="nvidia"
    elif lspci | grep -i intel > /dev/null; then
      GPU_TYPE="intel"
    elif lspci | grep -i amd > /dev/null; then
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
