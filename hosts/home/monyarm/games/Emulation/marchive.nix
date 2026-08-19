{
  config,
  lib,
  pkgs,
  fetchSteam,
  ...
}:
let
  # same decryption key/param across every Konami/Capcom alldata archive
  unpackWith =
    name: extra: fetched:
    pkgs.runCommand "${name}-marchive-extracted"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        cp "$(find "${fetched}" -name alldata.bin)" "$(find "${fetched}" -name alldata.psb.m)" .
        chmod +w alldata.bin alldata.psb.m
        ${pkgs.marchive-batch-tool}/bin/MArchiveBatchTool fullunpack --keep alldata.psb.m zlib 25G/xpvTbsb+6 64
        mkdir -p $out
        cp -r alldata.psb.m_extracted/system/roms/. $out/
        ${extra}
      '';
  unpack = name: unpackWith name "";

  # MArchiveBatchTool's generic unpack doesn't produce Kid Dracula's SRAM
  # save data -- pulled from an 8KiB hex byte array embedded in
  # 073/script/title_standalone.nut (script id 073 = dracula_kun). RED-Project
  # wiki's own command uses sfk, not packaged in nixpkgs; reimplemented with
  # awk/grep/python3. Bounded by `m_sram_data = [ ... ];` markers, not
  # hardcoded line numbers, so it survives MArchiveBatchTool output changes.
  kidDraculaSavExtra = ''
    awk '/m_sram_data = \[/{flag=1; next} /\];/{if(flag) exit} flag' \
      alldata.psb.m_extracted/073/script/title_standalone.nut \
      | grep -o '0x[0-9a-fA-F][0-9a-fA-F]' | cut -c3-4 | tr -d '\n' \
      | ${pkgs.python3}/bin/python3 -c 'import sys, binascii; sys.stdout.buffer.write(binascii.unhexlify(sys.stdin.read()))' \
      > $out/kid-dracula.sav
  '';

in
{
  options.games.emulation.marchive = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = ''
      Registry of extracted alldata roms/ dirs, keyed by title, for
      MArchive-format (Konami/Capcom "alldata.bin") game collections.
    '';
  };

  config = lib.mkIf config.games.emulation.enable {
    games.emulation.marchive = {
      contra =
        fetchSteam {
          filelist = [
            "windata/alldata.bin"
            "windata/alldata.psb.m"
          ];
          appId = 1018020;
          depotId = 1018021;
          manifestId = 6443479726234578030;
          sha256 = "sha256-qNeuZTnsddh36ZTH0VS6YdSoeb3BlCW7Hd/mZEy7oSQ=";
        }
        |> unpack "contra";

      castlevaniaAnniversary =
        fetchSteam {
          filelist = [
            "windata/alldata.bin"
            "windata/alldata.psb.m"
          ];
          appId = 1018010;
          depotId = 1018011;
          manifestId = 4125351698578021580;
          sha256 = "sha256-REhFKIssc3IfLjR6sAZXaYDXvP6tz69wuPq545B0+fc=";
        }
        |> unpackWith "castlevania-anniversary" kidDraculaSavExtra;

      castlevaniaAdvance =
        fetchSteam {
          filelist = [
            "windata/alldata.bin"
            "windata/alldata.psb.m"
          ];
          appId = 1552550;
          depotId = 1552551;
          manifestId = 8609910394922333285;
          sha256 = "sha256-tK/e8Ch266UTWzGfoWsDksMKlgVZaO0zB07KDpvQsds=";
        }
        |> unpack "castlevania-advance";
    };

    programs.steam.games = {
      CONTRA_ANNIVERSARY_COLLECTION_SOURCE = {
        disabled = true;
        name = "Contra Anniversary Collection";
        steamAppId = 1018020;
      };
      CASTLEVANIA_ANNIVERSARY_COLLECTION_SOURCE = {
        disabled = true;
        name = "Castlevania Anniversary Collection";
        steamAppId = 1018010;
      };
      CASTLEVANIA_ADVANCE_COLLECTION_SOURCE = {
        disabled = true;
        name = "Castlevania Advance Collection";
        steamAppId = 1552550;
      };
    };
  };
}
