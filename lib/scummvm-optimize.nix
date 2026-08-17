{
  pkgs,
  lib,
  sanitizeName,
  removeFiles,
  optimize,
  ...
}:
let
  cli = "${pkgs.scummvm-tools}/bin/scummvm-tools-cli";

  baseCruft = import ./cruft.nix;

  # scummvm-only chrome, hand-verified per entry (exe check below).
  # baseCruft/gogCruft merged in too, for non-GOG-fetched games.
  scummvmCruft = baseCruft ++ [
    "*.html" # manuals
    "*.manifest" # win manifests
    "*.dll"
    "*.so"
    "unins*.exe"
    "unins*.dat"
    "unins*.msg"
    "winsetup.exe" # AGS's own separate config GUI, never the game itself.
    "INSTALL.EXE"
    "SETUP.EXE"
    "scummvm-*.zip" # ScummVM's own source code archive, never the game itself.
  ];

  # Per-engine additions to scummvmCruft, only for entries individually
  # checked against a real scummvm-src clone (grep across the whole engine
  # directory, not just the obvious resource-loading file) -- filename
  # patterns here look identical to real load-bearing files often enough
  # (e.g. SCI's MT32.DRV/VGA320.DRV/SCIWV.EXE/RESOURCE.CFG are all *actually
  # read* by ScummVM's sci engine, despite looking like installer chrome)
  # that guessing from convention alone is not safe. Anything not listed
  # here was left alone rather than risk deleting real game data.
  scummvmEngineCruft = {
    # SCI0/1/1.1 DOS installer chrome (Sierra's own installer wizard +
    # hardware driver files for cards ScummVM's own backend never touches).
    # Verified zero references anywhere in engines/sci against upstream
    # scummvm/scummvm@master; explicitly NOT included: MT32.DRV, VGA320.DRV,
    # VGA320BW.DRV, ADL.DRV, GENMIDI.DRV (real MT-32/Adlib patch data and
    # render-mode detection), SCIWV.EXE (real Windows-16-color driver data),
    # RESOURCE.CFG (real -- metaengine.cpp reads it for language detection).
    sci = [
      "SIERRA.EXE"
      "SIERRA.BMP"
      "SIERRA.INI"
      "SIERRAW.ICO"
      "RA.BAT"
      "README.BAT"
      "INSTALL.INI"
      "INSTALL.SCR"
      "INSTALL.INS"
      "INSTALL.HLP"
      "INSTALL.EX$"
      "INTERP.ERR"
      "AUDNONE.DRV"
      "AUDPRO16.DRV"
      "AUDPRO.DRV"
      "AUDPS1.DRV"
      "AUDDISNY.DRV"
      "AUDBLAST.DRV"
      "AUDTHUND.DRV"
      "PROAUDIO.DRV"
      "STD.DRV"
      "JOYSTICK.DRV"
      "IBMKBD.DRV"
      "IBMPS1.DRV"
      "RESOURCE.GEN"
      "RESOURCE.PRO"
      "RESOURCE.SB"
      "RESOURCE.STD"
      "RESOURCE.THN"
      "RESOURCE.MT"
    ];
    # AGI's own (unrelated) installer/interpreter-overlay chrome. Verified
    # zero references in engines/agi, except hgc_graf.ovl -- which font.cpp
    # only reads inside a dead `#if 0` block -- and NOT including hgc_font,
    # which font.cpp genuinely opens for Hercules hi-res font support.
    agi = [
      "AGIDATA.OVL"
      "CGA_GRAF.OVL"
      "EGA_GRAF.OVL"
      "HGC_GRAF.OVL"
      "HGC_OBJS.OVL"
      "IBM_OBJS.OVL"
      "JR_GRAF.OVL"
      "SIERRA.COM"
      "Support.ico"
      "run.bat"
    ];
    # GOG's own DOSBox port (bundled for the original DOS interpreter, which
    # ScummVM's mads engine reimplementation never runs) plus this engine's
    # own installer artifacts (Return of the Phantom's separate CD-installer
    # detection files, Dragonsphere's raw installer payload) -- verified
    # zero references in engines/mads.
    mads = [
      "dosbox_windows"
      "dosbox_linux"
      "dosbox_osx"
      "GAME.GOG"
      "GAME.INS"
      "MPSCOPY.EXE"
      "MPSLABS.001"
      "MPSLABS.IDX"
      "CD.ROM"
      "UNRIP.WAV"
    ];
    # King of Dragon Pass's GOG build bundles a full Chromium Embedded
    # Framework (CEF) for the original game's own UI shell -- ScummVM's
    # mtropolis engine is a clean-room reimplementation that never links
    # against or reads any of it. Verified zero references in
    # engines/mtropolis (libcef.dll/d3dcompiler_*.dll/widevinecdmadapter.dll/
    # videoInput.dll/libEGL.dll/libGLESv2.dll already covered by the
    # universal "*.dll" rule above).
    mtropolis = [
      "cef.pak"
      "cef_100_percent.pak"
      "cef_200_percent.pak"
      "cef_extensions.pak"
      "cefclient.exe"
      "icudtl.dat"
      "natives_blob.bin"
      "snapshot_blob.bin"
      "locales"
      "s3eWebView.js" # Marmalade/S3E mobile WebView JS bridge, not game data
    ];
  };

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
            ${pkgs.coreutils}/bin/cp -as "${originalDrv}/." "$out/"
          else
            ${pkgs.coreutils}/bin/cp -as "${compressedDrv}/." "$out/"
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
        cp -as "${gameDrv}/." "$work/"
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
        # $lower is the pre-compression scratch copy compress_sci read from,
        # not its output -- it survives untouched otherwise, silently
        # doubling this file's size and tricking guardDirSize into rejecting
        # the (correctly) smaller compressed result.
        if [ "$f" != "$lower" ]; then
          rm -f "$lower"
        fi
      else
        rm -f "$lower.new"
        if [ "$f" != "$lower" ]; then
          mv -f "$lower" "$f"
        fi
      fi
    done || true
  '';

  # scummvm-tools' Tool::_outputToDirectory defaults to true and this tool
  # never overrides it, so -o is ALWAYS directory-mode upstream (a trailing
  # '/' gets forced on whatever we pass, before execute() ever sees it) --
  # passing a constructed destination filename here just makes the tool
  # nest its own hardcoded output name inside a directory named after that
  # filename (e.g. -o "MONSTER.sof" -> "MONSTER.sof/monster.sof", which
  # doesn't exist as a real directory and fatal-errors on open). The actual
  # output name is never ours to choose: compress_scumm_sou hardcodes it
  # per codec (monster.sof for FLAC) regardless of the input's name. Pass a
  # real directory and let it do that.
  compressScummSou = ''
    find . -iname '*.sou' | while IFS= read -r f; do
      dir=$(dirname "$f")
      if ${cli} --tool compress_scumm_sou --flac -o "$dir" "$f"; then
        rm -f "$f"
      else
        rm -f "$dir/monster.sof"
      fi
    done || true
  '';

  # Also auto-patches the companion .flu file to point at the new name
  # (per upstream README); best-effort, unverified against a real game.
  # Its output-directory/naming convention (this tool doesn't take -o) is
  # untested here, so unlike the others this doesn't delete the original --
  # avoid guessing at a filename to rm and risking losing data instead.
  # Unlike every other compress_* tool here, this one does NOT support FLAC
  # (compress_scumm_san.cpp hard-errors "Only ogg vorbis and MP3 are
  # supported for this tool" on AUDIO_FLAC) -- don't "fix" this to match.
  compressScummSan = ''
    find . -iname '*.san' | while IFS= read -r f; do
      ${cli} --tool compress_scumm_san --vorbis "$f" || true
    done
  '';

  # Upstream notes FLAC can produce *larger* output than the original for
  # this engine -- guardDirSize (folder-level) covers that, same as
  # guardSize does for the single-file optimize.nix pipelines.
  # Same -o-is-always-a-directory upstream behavior as compressScummSou
  # above (Tool::_outputToDirectory defaults true, unset here too): when
  # forced into directory mode this tool reuses the *input's* own basename
  # and swaps the extension to .clf, so a constructed destination filename
  # collides with that same-named directory instead of naming the file.
  # Pass a real directory; "''${f%.*}.clf" is still the name the tool itself
  # produces there, so it's the right path to clean up on failure.
  compressSword2 = ''
    find . -iname '*.clu' | while IFS= read -r f; do
      dir=$(dirname "$f")
      if ${cli} --tool compress_sword2 --flac -o "$dir" "$f"; then
        rm -f "$f"
      else
        rm -f "''${f%.*}.clf"
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

  cruftAgs = ''
    find . \( \
      -iname 'ags32' -o -iname 'ags64' \
      -o -iname 'ags32.exe' -o -iname 'ags64.exe' \
      -o -iname 'licenses' \
      -o -iname 'Game.sh' -o -iname 'lib32' -o -iname 'lib64' \
      \) \
      -delete || true
  '';

  engineGatedScripts = {
    agos = compressAgos;
    kyra = compressKyra;
    saga = compressSaga;
    sword1 = compressSword1;
    touche = compressTouche;
    tucker = compressTucker;
    tinsel = compressTinsel;
    ags = cruftAgs;
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
  # Pipes a fetched ScummVM game folder through: universal installer-cruft
  # removal, then whichever scummvm-tools compress_* passes apply to it
  # (guarding each against the possibility that "compressed" comes out
  # larger -- documented for several engines upstream, e.g. compress_sword2's
  # FLAC output), then a blanket optimize pass over whatever's left (png/jpg/
  # mp3/ogg/etc -- most of a game folder's bytes have no matching handler and
  # pass through untouched; relying on auto-optimise-store to hardlink those
  # back down rather than skipping the walk). Safe (and intended) to call at
  # every ScummVM game's fetch site regardless of engine: engines with no
  # matching compress_* tool at all just skip straight to cruft+optimize
  # without paying for a folder copy that could never find anything to
  # compress.
  compressScummvmGame =
    # A bare engineid string is shorthand for `{ engineid = ...; }` -- the
    # common case, since almost every call site has no other option to set.
    argsOrEngineid:
    let
      args = if builtins.isString argsOrEngineid then { engineid = argsOrEngineid; } else argsOrEngineid;
      inherit (args) engineid;
      sciSupported = args.sciSupported or false; # gate compress_sci per-game: NOT SCI32-safe
    in
    gameDrv:
    let
      isRelevant =
        builtins.elem engineid formatDetectedEngines
        || engineGatedScripts ? ${engineid}
        || (engineid == "sci" && sciSupported);
      cleaned = removeFiles (scummvmCruft ++ (scummvmEngineCruft.${engineid} or [ ])) gameDrv;
      compressed =
        if !isRelevant then
          cleaned
        else
          let
            scripts =
              formatDetectedScripts
              ++ lib.optional sciSupported compressSci
              ++ lib.optional (engineGatedScripts ? ${engineid}) engineGatedScripts.${engineid};
          in
          guardDirSize (compressPass cleaned (lib.concatStringsSep "\n" scripts)) cleaned;
    in
    optimize compressed;
}
