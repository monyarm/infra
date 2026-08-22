{ fetchSteam, splitFiles, ... }:
{
  planetaryAnnihilation =
    let
      files = [
        "media/pa_ex1/ui/splash/unicorn-splash.png"
        "media/pa_ex1/ui/splash/invictus-splash.png"
        "media/pa_ex1/ui/splash/splash.png"
        "media/pa_ex1/ui/splash/halloween-splash.png"
      ];
    in
    fetchSteam {
      appId = 386070;
      depotId = 386074;
      manifestId = 2114814930327484635;
      sha256 = "sha256-mOX4N9dWL2AOl16qupWbdJdFRRE2O1wmiQdPZUI7U0c=";
      filelist = files;
    }
    |> splitFiles files;
}
