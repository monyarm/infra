# Known plugins: destination, runlevel, and pinned download, so a plugin can be
# enabled without being redefined. `source = null` means the user must supply
# one; enabling that then is a config error, not a silent no-op.
{
  pkgs,
  fetchGameBrew ? null,
}:

let
  # Release binaries fetched by URL. `hash` is SRI sha256 of the file.
  fetchAsset =
    url: hash:
    pkgs.fetchurl {
      inherit url hash;
    };

  # Releases that ship a zip: extract the single .prx to a stable output path.
  fetchPrxFromZip =
    {
      url,
      hash,
      name,
      file,
    }:
    pkgs.runCommand "psp-plugin-${name}"
      {
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
                unzip -q ${
                  pkgs.fetchurl {
                    inherit url hash;
                  }
                } -d unpacked
                prx=$(find unpacked -type f -name '${file}' | head -n1)
                if [ -z "$prx" ]; then
                  echo "psp plugin ${name}: ${file} not found in archive" >&2
                  exit 1
                fi
                # $out is the binary itself, matching what fetchurl produces, so a
                # plugin entry is always a single file regardless of how it was packaged.
        cp "$prx" "$out"
      '';

  # Some archives unpack into versioned directories; reduce one to the single
  # .prx we want so a plugin entry is always a file.
  pickPrx =
    tree: file:
    pkgs.runCommand "psp-prx-pick" { nativeBuildInputs = [ pkgs.findutils ]; } ''
      prx=$(find ${tree} -type f -name '${file}' | head -n1)
      if [ -z "$prx" ]; then
        echo "psp plugin: ${file} not found under ${tree}" >&2
        exit 1
      fi
      # $out is the binary itself, not a directory: a plugin entry is a file.
      cp "$prx" "$out"
    '';

  # CWCheat has no maintained fork or GitHub release, so it comes from the
  # gamebrew.org archive. `cwcheat6xx.7z` holds the 6.60 build, which is the one
  # that runs on modern CFW.
  cwcheatPrx =
    if fetchGameBrew == null then
      null
    else
      pickPrx (fetchGameBrew {
        name = "cwcheat-archive";
        url = "https://www.gamebrew.org/wiki/CWCheat_PSP";
        file = "cwcheat6xx.7z";
        hash = "sha256-FxThew4jhdi0zGYTDzqV5aivs43RM57YYfjr8ylyPSk=";
      }) "cwcheat.prx";

  cwcheatPopsPrx =
    if fetchGameBrew == null then
      null
    else
      pickPrx (fetchGameBrew {
        name = "cwcheat-bundle";
        url = "https://www.gamebrew.org/wiki/CWCheat_PSP";
        file = "cwcheatbundle.7z";
        hash = "sha256-QM2+MrQraBcn9UER2ykEtD53s8g/2K88h8pfoY2DbIY=";
      }) "cwcheatpops.prx";
in
rec {
  # Must be the FIRST plugin listed: Categories Lite patches VSH item drawing
  # and later VSH plugins can override it.
  categories-lite = {
    description = "Turn PSP/GAME and ISO subfolders into XMB category folders.";
    homepage = "https://github.com/codestation/gclite";
    license = "GPL-2.0";
    version = "1.6";
    dest = "SEPLUGINS/category_lite.prx";
    runlevel = "vsh";
    order = -100;
    source = fetchPrxFromZip {
      name = "categories-lite";
      url = "https://github.com/codestation/gclite/releases/download/1.6/categories_lite-1.6.zip";
      hash = "sha256-w7baoGUj5tFxQOA2fJHZbINa/Du9J5L1fes7a0fd2FI=";
      file = "category_lite.prx";
    };
  };

  missyhud = {
    description = "HUD showing the currently loaded module and load progress.";
    homepage = "https://github.com/pebeto/missyhud.prx";
    license = "MIT";
    version = "0.7";
    dest = "SEPLUGINS/missyhud.prx";
    # Its README documents `game, ms0:/seplugins/missyhud.prx, on`.
    runlevel = "game";
    source = fetchAsset "https://github.com/pebeto/missyhud.prx/releases/download/v0.7/missyhud.prx" "sha256-YCiSuGCqTg6HrZ2t+sgupgufm6IuMMxW4L31h5e0H1M=";
  };

  kill-switch = {
    description = "Disables the physical power switch, with a hold variant.";
    homepage = "https://github.com/crozone/PSP-KillSwitch";
    license = "GPL-3.0";
    version = "1.3.0";
    dest = "SEPLUGINS/KillSwitch.prx";
    # Its README documents `game, ms0:/SEPLUGINS/KillSwitch.prx, on`.
    runlevel = "game";
    source = fetchAsset "https://github.com/crozone/PSP-KillSwitch/releases/download/1.3.0/KillSwitch.prx" "sha256-OW6mLo7GobpXopumXdFV+TuHQEidZ3PAF9AVYdSxtBs=";
  };

  # Declared but not downloadable from a stable pinned URL, so the user must
  # supply `source`. Paths and runlevels follow each plugin's own docs.
  cxmb = {
    description = "Custom XMB: applies .ctf themes from PSP/SAVEDATA.";
    homepage = "https://github.com/cello0314/CXMB";
    license = "GPL-3.0";
    version = "1.2.1";
    dest = "SEPLUGINS/cxmb.prx";
    runlevel = "vsh";
    source = fetchAsset "https://github.com/cello0314/CXMB/releases/download/v1.2.1/cxmb.prx" "sha256-97mnBd98ClJ6fjcDrdqO97pPVjaXnF8Juto6odiIX/o=";
  };

  cwcheat = {
    description = "Cheat engine reading .cwch files and the cwch database.";
    homepage = "https://www.gamebrew.org/wiki/CWCheat_PSP";
    license = "unknown";
    version = "0.2.3";
    dest = "SEPLUGINS/cwcheat.prx";
    runlevel = "game";
    source = cwcheatPrx;
  };

  cwcheat-pops = {
    description = "CWCheat build for PS1 titles under POPS.";
    homepage = "https://www.gamebrew.org/wiki/CWCheat_PSP";
    license = "unknown";
    version = "0.2.3";
    dest = "SEPLUGINS/cwcheatpops.prx";
    runlevel = "pops";
    source = cwcheatPopsPrx;
  };

  prxshot = {
    description = "Screenshot plugin, writes PNGs per game folder.";
    homepage = "https://github.com/codestation/prxshot";
    license = "unknown";
    dest = "SEPLUGINS/prxshot.prx";
    runlevel = "game";
    source = null;
  };
}
