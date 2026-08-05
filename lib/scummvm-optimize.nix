{
  pkgs,
  lib,
  sanitizeName,
  ...
}:
let
  cli = "${pkgs.scummvm-tools}/bin/scummvm-tools-cli";

  # guardSize (from optimize.nix) compares single files via `stat`; a whole
  # compressed game folder needs a recursive size total instead.
  guardDirSize =
    compressedDrv: originalDrv:
    derivation {
      name = "${originalDrv.name}-g";
      system = pkgs.stdenv.hostPlatform.system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          origSize=$(${pkgs.coreutils}/bin/du -sb "${originalDrv}" | ${pkgs.coreutils}/bin/cut -f1)
          newSize=$(${pkgs.coreutils}/bin/du -sb "${compressedDrv}" | ${pkgs.coreutils}/bin/cut -f1)
          ${pkgs.coreutils}/bin/mkdir -p "$out"
          if [ "$newSize" -gt "$origSize" ]; then
            ${pkgs.coreutils}/bin/cp -a "${originalDrv}/." "$out/"
          else
            ${pkgs.coreutils}/bin/cp -a "${compressedDrv}/." "$out/"
          fi
          exit 0;
        ''
      ];
      # Not preferLocalBuild: this runs right after compressPass, which is
      # already free to run remotely -- same reasoning as optimize.nix's
      # guardSize.
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };

  # Runs `script` (a bash snippet) with $PWD at the root of a writable copy
  # of gameDrv; script is responsible for compressing whatever it finds and
  # deleting the now-superseded originals. A script that finds nothing to
  # do is a correct no-op -- the copy is then identical to the original and
  # guardDirSize picks the original anyway (skipping the wasted copy isn't
  # worth the extra complexity here).
  #
  # Work happens in a scratch dir, not $out itself: several compress_*
  # tools drop hardcoded scratch files (e.g. compress_sci's tempfile.raw/
  # tempfile.enc) into the current directory and don't always clean them
  # up when they error out (real example: Torin's Passage's audio hits a
  # documented upstream parser limitation and fatal-errors, leaving a
  # stray tempfile behind) -- when that directory *is* $out, whatever gets
  # left over becomes part of this __contentAddressed derivation's output
  # and can break Nix's post-build NAR hashing even though the script
  # itself exited 0. Only the final, cleaned-up state gets copied to $out.
  compressPass =
    gameDrv: script:
    pkgs.runCommand "${sanitizeName gameDrv.name}-scummvm-compressed"
      {
        buildInputs = [
          pkgs.scummvm-tools
          pkgs.findutils
        ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        work="$TMPDIR/work"
        mkdir -p "$work"
        cp -a "${gameDrv}/." "$work/"
        chmod -R u+w "$work"
        cd "$work"
        ${script}
        cd /
        # $work and $out are the same filesystem inside the sandbox, so this
        # is a cheap rename (no second full copy of the game data needed).
        mv "$work" "$out"
      '';

  # --- format-detected tools -----------------------------------------
  # Each of these keys off a specific, essentially-unmistakable filename or
  # glob actually present in the game folder, independent of the game's
  # declared engineid.

  # compress_queen unconditionally requires a companion queen.tbl resource
  # table -- not part of the game data itself, but a separate file the
  # ScummVM project distributes independently (not currently fetched by
  # this repo). Skip cleanly rather than fail the whole game's build until
  # that's wired up as its own source.
  # runCommand's script runs under `set -e`; a single tool call failing on
  # some game's particular data quirk (real example hit during testing:
  # compress_sci fatal-erroring on Torin's Passage's raw lipsync audio,
  # a documented upstream limitation) must not take down the whole game's
  # build. Every invocation below is therefore wrapped in an if/then so a
  # failure just leaves that one file uncompressed instead of aborting.

  compressQueen = ''
    q1=$(find . -maxdepth 1 -iname 'queen.1' | head -1)
    qtbl=$(find . -maxdepth 1 -iname 'queen.tbl' | head -1)
    if [ -n "$q1" ] && [ -n "$qtbl" ]; then
      if ${cli} --tool compress_queen --flac "$q1"; then
        rm -f "$q1" "$qtbl"
      fi
    fi
  '';

  # NOT SCI32-compatible (upstream source comment) -- only ever invoked for
  # confirmed SCI0/SCI1/SCI1.1 games at the call site below.
  # DOS-era GOG installs keep their original 8.3 filenames, which are
  # typically UPPERCASE (RESOURCE.AUD, not resource.aud); compress_sci's
  # own input-matching against its "resource.*" ToolInput glob is
  # case-sensitive and rejects DOS-cased RESOURCE.AUD outright ("Unexpected
  # input file"), so run it against a lowercased copy and restore the
  # original name afterward either way.
  compressSci = ''
    find . -maxdepth 1 \( -iname 'resource.aud' -o -iname 'resource.sfx' -o -iname 'audio001.002' \) -printf '%f\n' | while IFS= read -r f; do
      lower=$(echo "$f" | tr '[:upper:]' '[:lower:]')
      if [ "$f" != "$lower" ]; then
        mv -f "$f" "$lower"
      fi
      if ${cli} --tool compress_sci --flac -o "$lower.new" "$lower"; then
        mv -f "$lower.new" "$f"
      else
        rm -f "$lower.new"
        if [ "$f" != "$lower" ]; then
          mv -f "$lower" "$f"
        fi
      fi
    done || true
  '';

  compressScummSou = ''
    find . -iname '*.sou' | while IFS= read -r f; do
      out="''${f%.*}.sof"
      if ${cli} --tool compress_scumm_sou --flac -o "$out" "$f"; then
        rm -f "$f"
      else
        rm -f "$out"
      fi
    done || true
  '';

  # Also auto-patches the companion .flu file to point at the new name
  # (per upstream README); best-effort, unverified against a real game.
  # Its output-directory/naming convention (this tool doesn't take -o) is
  # untested here, so unlike the others this doesn't delete the original --
  # avoid guessing at a filename to rm and risking losing data instead.
  compressScummSan = ''
    find . -iname '*.san' | while IFS= read -r f; do
      ${cli} --tool compress_scumm_san --flac "$f" || true
    done
  '';

  # Upstream notes FLAC can produce *larger* output than the original for
  # this engine -- guardDirSize (folder-level) covers that, same as
  # guardSize does for the single-file optimize.nix pipelines.
  compressSword2 = ''
    find . -iname '*.clu' | while IFS= read -r f; do
      out="''${f%.*}.clf"
      if ${cli} --tool compress_sword2 --flac -o "$out" "$f"; then
        rm -f "$f"
      else
        rm -f "$out"
      fi
    done || true
  '';

  # README: .gob config files are produced by a separate extract_gob_stk
  # pre-pass, not present in a plain install -- likely a no-op in practice.
  # Same no-known-output-name caveat as compress_scumm_san above.
  compressGob = ''
    find . -iname '*.gob' | while IFS= read -r f; do
      ${cli} --tool compress_gob --flac "$f" || true
    done
  '';

  # --- engine-gated tools ----------------------------------------------
  # These take a whole directory / `*.*` glob (can't be told apart by
  # filename pattern alone), so `engineid` selects the tool instead. None
  # of the games currently registered exercise these -- best-effort,
  # unverified against a real build.

  compressAgos = ''
    ${cli} --tool compress_agos --flac . || true
  '';

  compressKyra = ''
    ${cli} --tool compress_kyra --flac . || true
  '';

  compressSaga = ''
    ${cli} --tool compress_saga --flac . || true
  '';

  compressSword1 = ''
    ${cli} --tool compress_sword1 --flac . || true
  '';

  compressTouche = ''
    ${cli} --tool compress_touche --flac . || true
  '';

  compressTucker = ''
    ${cli} --tool compress_tucker --flac . || true
  '';

  compressTinsel = ''
    if find . -iname '*.smp' | grep -q . && find . -iname '*.idx' | grep -q .; then
      smp=$(find . -iname '*.smp' | head -1)
      idx=$(find . -iname '*.idx' | head -1)
      ${cli} --tool compress_tinsel --flac "$smp" "$idx" || true
    fi
  '';

  engineGatedScripts = {
    agos = compressAgos;
    kyra = compressKyra;
    saga = compressSaga;
    sword1 = compressSword1;
    touche = compressTouche;
    tucker = compressTucker;
    tinsel = compressTinsel;
  };

  formatDetectedScripts = [
    compressQueen
    compressScummSou
    compressScummSan
    compressSword2
    compressGob
  ];

  # Engines whose format-detected scripts could plausibly find something
  # (scumm/queen/sword2/gob file conventions are engine-specific, so a
  # non-matching engine's data can never trip them).
  formatDetectedEngines = [
    "scumm"
    "queen"
    "sword2"
    "gob"
  ];
in
{
  # Pipes a fetched ScummVM game folder through whichever scummvm-tools
  # compress_* passes apply to it, guarding each against the possibility
  # that "compressed" comes out larger (documented for several engines
  # upstream, e.g. compress_sword2's FLAC output). Safe (and intended) to
  # call at every ScummVM game's fetch site regardless of engine: engines
  # with no matching compress_* tool at all short-circuit to the original
  # derivation untouched, without paying for a folder copy that could
  # never find anything to compress.
  compressScummvmGame =
    {
      engineid,
      sciSupported ? false, # gate compress_sci per-game: NOT SCI32-safe
    }:
    gameDrv:
    let
      isRelevant =
        builtins.elem engineid formatDetectedEngines
        || engineGatedScripts ? ${engineid}
        || (engineid == "sci" && sciSupported);
    in
    if !isRelevant then
      gameDrv
    else
      let
        scripts =
          formatDetectedScripts
          ++ lib.optional sciSupported compressSci
          ++ lib.optional (engineGatedScripts ? ${engineid}) engineGatedScripts.${engineid};
        compressed = compressPass gameDrv (lib.concatStringsSep "\n" scripts);
      in
      guardDirSize compressed gameDrv;
}
