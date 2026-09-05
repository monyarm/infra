{
  config,
  lib,
  pkgs,
  fetchSteam,
  splitFiles,
  mkRom,
  ...
}:
let
  # roms baked inside capcom_disney_afternoon.exe; game-extraction-toolbox extracts them
  DAC = fetchSteam {
    filelist = [ "capcom_disney_afternoon.exe" ];
    appId = 525040;
    depotId = 525041;
    manifestId = 5256007417415092342;
    sha256 = "sha256-kOrgNdOBJpLBkseOX2THJ4/KPj+Ej+z6FZILbG33rVM=";
  };

  dacExtracted =
    pkgs.runCommand "game-extraction-toolbox-dac-roms"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        ${pkgs.game-extraction-toolbox}/bin/gextoolbox tasks extract \
          --srcdir "${DAC}" \
          --destdir "$out" \
          --task disneyac
        rm -rf "$out/capcom_disney_afternoon.exe"
      '';

  # Extracted ROMs have all Nintendo references removed, not byte-identical to original cartridges.
  # No known IPS patches exist to restore them.
  dacRomNames = [
    "Chip n Dale - Rescue Rangers (DAC).nes"
    "Chip n Dale - Rescue Rangers 2 (DAC).nes"
    "Darkwing Duck (DAC).nes"
    "DuckTales (DAC).nes"
    "DuckTales 2 (DAC).nes"
    "TaleSpin (DAC).nes"
  ];

  dacRoms = lib.listToAttrs (
    lib.zipListsWith lib.nameValuePair [
      "chipNDale1"
      "chipNDale2"
      "darkwingDuck"
      "duckTales1"
      "duckTales2"
      "taleSpin"
    ] (splitFiles dacRomNames dacExtracted)
  );
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (dacRoms)
      chipNDale1
      chipNDale2
      darkwingDuck
      duckTales1
      duckTales2
      taleSpin
      ;
  };

  programs.steam.games = with config.games.emulation.roms; {
    CHIP_N_DALE_1 = mkRom {
      name = "Chip 'n Dale - Rescue Rangers";
      rom = chipNDale1;
      system = "nes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/171b3569124a791f200cd7be51be1a43.png";
        sha256 = "sha256-1wOf/PYcymO/V+zHFx+Ke92B5GX8C8kU7z1ZElQejQQ=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/006730204165965b7e5f7dc9c4b63f92.png";
        sha256 = "sha256-yTht1bxsSpAXw6idK1eNsC6lxXkZ6weJFK34MlXHvPo=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/0e622da2946dfae5694dd2a888cf8c37.png";
        sha256 = "sha256-O7X1qNFJWxjPXb6b3O9Rwb86rkwKX0l9awWlFd0drtI=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/301177f5a6d749487c3804830662d488.png";
        sha256 = "sha256-zNMqloNy1GnGoXIx/by1b/H0A+H5ppZUwse8IamXxQU=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/6a33d1b2f6875b0b5a40b39b53492993.jpg";
        sha256 = "sha256-Eqfk5XYeg14tyyriZLmjbccUFhAC3W0cxU78R8uCrEU=";
      };
    };
    CHIP_N_DALE_2 = mkRom {
      name = "Chip 'n Dale - Rescue Rangers 2";
      rom = chipNDale2;
      system = "nes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/d629eddc95ad3b072b33e5363def437f.png";
        sha256 = "sha256-l4IAYlNtEsO8U6S1qyPTobYU6FsdTF1U9GPmN3RsDx4=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/ee3b82c0e2e4bfc25da9d31e9f754061.png";
        sha256 = "sha256-r7UiTrFNaXBhyk1KYaaZeGL/ECPuya2A0QwWcbyq0Ys=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/97ad1094c0fa4b38fc6b44ba2014dab6.png";
        sha256 = "sha256-3t5SXRG/lxgvVQEewezrjTdV8maMhDqYhzk85uJ63S0=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/12988e0d9a54da773167af3d7764b697.png";
        sha256 = "sha256-HFOaTnYVdBZE+E1QcKwX9ZXVOz9QfGvCPDY8i94I/Fo=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/dbca9b6b925adaae881af122e58d8a2b.png";
        sha256 = "sha256-tk9RRGq7EvFhkTZMtwo9EYyQ095wK6vuRrvtpkrUl78=";
      };
    };
    DARKWING_DUCK = mkRom {
      name = "Darkwing Duck";
      rom = darkwingDuck;
      system = "nes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/f869d4accedf2bf6b9469a3be9f1d715.png";
        sha256 = "sha256-xh4NS6AVMsIrw1tSGZgUn9bOeavmVMhDe1lkhA0wdho=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/420e7a59c4ccc0dbeb1d58e2126c42d5.jpg";
        sha256 = "sha256-GENThK5xhE+VcwipxJQLe1hH5K3j6i3jXLRXIxUUR/c=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/4bf269bdf9a80bc227aa079d668e22c4.png";
        sha256 = "sha256-W9xsVvTTI72RqwIKoBnQM82NWHFU+SHX+feAkUmbSYI=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/6b3625aa6d5c8d8a9b212bab6f8085dd.png";
        sha256 = "sha256-Q+Euy/r/ckgJ2Q8pqT65/4uiny4m/VvsSPYHywP/eBc=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/4e62ef3e34c3922e68f90b9358f8be0b.png";
        sha256 = "sha256-mRXVTXhyODVEOuEa9yzDXu+RFQpeZPEIPC792Cuptm4=";
      };
    };
    DUCKTALES_1 = mkRom {
      name = "DuckTales";
      rom = duckTales1;
      system = "nes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/2fbdd77210d6beb40c3bd1bd026f63ed.png";
        sha256 = "sha256-3Nb3MZweVg/of8fH2/dlxqZ7br1yEpgwpKyGWVOYckY=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/b541f9935c1b4824b94f71c64ee36e6c.png";
        sha256 = "sha256-7sM+7KZ3C1Jn88lRLPA7pmOQuCjU3icO2D/qHGuLHhs=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/68ef436ae9a785541beefdeacb8433b2.png";
        sha256 = "sha256-xco3iIhuwuOwTGUtkX2zPQ7Cu5rbp+dDQcSRnQlk38Q=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/3902d3c0762ab4c7ea7b3a1611763ebd.jpg";
        sha256 = "sha256-FP0rDo7dK0LyNOIEbLdDRUb1IkisXH7lQsXlaDKr8as=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/67ba02d73c54f0b83c05507b7fb7267f.png";
        sha256 = "sha256-DePGV9OdMPTVtUqAVe7zcUkCPGqdXUaRvxQ0eNuE14s=";
      };
    };
    DUCKTALES_2 = mkRom {
      name = "DuckTales 2";
      rom = duckTales2;
      system = "nes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/81d9e5ac71dc30131919ef8778abe6a7.ico";
        sha256 = "sha256-Y2gQr0gbt0e1jbPtgpsBWrR5sHiusNDslgRRMiQWRp4=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/d4dd0335c67adb170e5f313f0d39b456.png";
        sha256 = "sha256-N7PuP7RBIJO1d/qiExjw72Jzw67RERbeQQ+5BoDd7tU=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/a6e388da46e5a3fee4ac7a633de3202f.png";
        sha256 = "sha256-8TcpdpDn4pc21VWMy6H6wbax9gDTpLnPw3baIKHE97w=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/16837163fee34175358a47e0b51485ff.png";
        sha256 = "sha256-gYANByd7pseWAelvODoFnCWeJt3P8VSUBUTflyZ6i9A=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/123650dd0560587918b3d771cf0c0171.png";
        sha256 = "sha256-LaWQ6nDY8XqBYYKPT5x0mMt7S6OBY/hmJWJ17Q0H7fA=";
      };
    };
    TALE_SPIN = mkRom {
      name = "TaleSpin";
      rom = taleSpin;
      system = "nes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/e6a3684de5e80c535db4f65de1d27041.png";
        sha256 = "sha256-CP2u9lAI0pWZ28ba1QA7xVvBknfEmpz0Ep0FBL4N2yc=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/b82bb348160c1143020224fb02609564.png";
        sha256 = "sha256-6VUK+KQZKmn8muGvvcH1QenpiHn0ymnyEuAunPM7K08=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/b5e2bddd17bc1c9af728f9c1bfd5728e.png";
        sha256 = "sha256-dUSc94ybVrh4DOzRlXeyJWadCxZtFpSat+o46zCv4sU=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/7e2b19cf536f050af54618000b14715e.png";
        sha256 = "sha256-ohdkrR/aa0VhceuGBxyt3mlajoM0Ak/fOt0NRGNGwSc=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/f7d39620fd98ccb30f1c7741fe158210.png";
        sha256 = "sha256-cPUDZIFll+CZuDcqB9202sECslyURPyaNIEHQS1dPnw=";
      };
    };

    DISNEY_AFTERNOON_COLLECTION_SOURCE = {
      disabled = true;
      name = "Disney Afternoon Collection";
      steamAppId = 525040;
    };
  };
}
