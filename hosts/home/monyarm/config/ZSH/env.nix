{ config, ... }:
{
  home.sessionVariables = {
    # TODO: remove most of these when I switch to nixOS
    DEFAULT_USER = config.home.username;
    EDITOR = "nano";
    AUTOENV_IN_FILE = ".env";
    MOZ_LEGACY_PROFILES = "1";
    ANDROID_HOME = "/opt/android-sdk-update-manager";
    QEMU_LD_PREFIX = "/usr/arm-linux-gnueabihf";
    AIR_HOME = "/opt/adobe-air-sdk";
    JAVA_HOME = "/usr/lib/jvm/default";
    NVM_DIR = "$HOME/.nvm";
    NVM_SOURCE = "/usr/share/nvm";
    JAYATANA_FORCE = "1";
    GOBIN = "$HOME/.local/bin";
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };
}
