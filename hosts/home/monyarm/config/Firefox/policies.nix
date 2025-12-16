{
  programs.firefox.policies = {
    DisableTelemetry = true;
    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
    };
    DisablePocket = true;
    DisableFirefoxAccounts = false;
    DisableAccounts = false;
    DisableFirefoxScreenshots = true;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    DontCheckDefaultBrowser = true;

  };
}
