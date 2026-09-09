{
  pkgs,
  lib,
  sources,
  fetchToolOutput,
  ...
}:
let
  # Only one physical drive can be read at a time regardless of which rip
  # strategy runs -- same shape as lib/optimize/dynamic.nix's
  # dynamic-optimize.lock (both rely on .envrc's extra-sandbox-paths
  # bind-mounting /build-locks in). ripDiscRedumper alone runs __noChroot
  # (see doasResolve below), where /build-locks -- a sandbox-side bind
  # target -- doesn't exist as a real path; fall back to the real one.
  flockBlock = ''
    lockDir=/build-locks
    [ -d "$lockDir" ] || lockDir=/tmp/build-locks
    if [ -d "$lockDir" ]; then
      exec 9>"$lockDir/cdrom.lock"
      flock 9
    fi
  '';

  helper = "${pkgs.disc-rip-helper}/bin/disc-rip-helper";

  # Only redumper's raw SCSI generic access actually needs root
  # (CAP_SYS_RAWIO, which file permissions alone can't grant -- confirmed
  # against redumper's own docs). ripDisc/ripDiscContents just need read
  # access to the block device, which an ACL grant covers (see .envrc) --
  # no doas, no __noChroot, stays fully sandboxed.
  #
  # doas lives at a different path depending on the host: NixOS's
  # security.wrappers convention puts it at /run/wrappers/bin/doas (plain
  # store binaries have no setuid bit under NixOS); Gentoo/portage
  # (monyarm, confirmed: -rws--x--x root:root) installs it as an ordinary
  # setuid system package at /usr/bin/doas. Test-and-pick at build-script
  # runtime rather than hardcoding one. Needs __noChroot (below) since doas
  # needs the real host's dynamic linker/PAM/nsswitch environment, which
  # isn't reconstructible via selective sandbox bind-mounts.
  doasResolve = ''
    doas=/usr/bin/doas
    [ -x "$doas" ] || doas=/run/wrappers/bin/doas
    [ -x "$doas" ] || { echo "disc fetcher: no doas binary at /usr/bin/doas or /run/wrappers/bin/doas" >&2; exit 1; }
  '';

  ownerArgs = "--owner-uid=$(id -u) --owner-gid=$(id -g)";

  # DAT -> JSON at eval time (IFD): the disc's identity isn't knowable until
  # it's actually read, but the DAT rarely changes and its store path is a
  # cheap stat on every eval after the first build -- deliberate one-off
  # exception to this repo's usual no-IFD convention.
  datJsonFor =
    system:
    let
      # sources.nix entries are raw metadata ({url, hash, type, ...}), not
      # pre-built derivations -- every other fetchers/*.nix caller
      # constructs the actual fetch itself the same way.
      # redump.org's datfile URLs have no file extension, so fetchzip can't
      # sniff the archive type from the URL -- tell it explicitly.
      datZip = pkgs.fetchzip {
        inherit (sources.redump.${system}) url hash;
        extension = "zip";
      };
    in
    builtins.fromJSON (
      builtins.readFile (
        pkgs.runCommand "redump-${system}-dat.json" { } ''
          ${pkgs.python3}/bin/python3 ${./py/dat-to-json.py} ${datZip} > $out
        ''
      )
    );

  # Lazy per Nix attrset semantics -- covers every system sources.toml's
  # [zip] redump.* block knows about, but only the ones an actual
  # ripDisc/ripDiscRedumper call names ever get IFD-built.
  datJson = lib.mapAttrs (system: _: datJsonFor system) sources.redump;
in
rec {
  # Raw whole-disc image (PS2 et al). Nix's own scheduler routes/refuses
  # this via requiredSystemFeatures instead of failing at build time
  # against a missing drive.
  ripDisc =
    {
      name,
      system,
      device ? "/dev/sr0",
    }:
    let
      entry = datJson.${system}.${name};
    in
    fetchToolOutput {
      name = "disc-${lib.strings.sanitizeDerivationName name}-image";
      outputHash = entry.sha1;
      outputHashMode = "flat";
      extraAttrs = {
        outputHashAlgo = "sha1";
        requiredSystemFeatures = [ "cdrom" ];
      };
      script = ''
        ${flockBlock}
        ${helper} --mode=image --title=${lib.escapeShellArg name} --device=${device} --out="$out"
      '';
    };

  # Extracted filesystem tree (PC games). Redump DATs describe raw disc
  # dumps, not post-extraction file trees, so there's no DAT entry to look
  # up here -- caller supplies the extracted tree's own sha256.
  ripDiscContents =
    {
      name,
      device ? "/dev/sr0",
      sha256,
    }:
    fetchToolOutput {
      name = "disc-${lib.strings.sanitizeDerivationName name}-contents";
      outputHash = sha256;
      outputHashMode = "recursive";
      extraAttrs = {
        requiredSystemFeatures = [ "cdrom" ];
      };
      script = ''
        ${flockBlock}
        ${helper} --mode=contents --title=${lib.escapeShellArg name} --device=${device} --out="$out"
      '';
    };

  # Accurate C2/subchannel dump. Two shapes depending on what the DAT entry
  # looks like for this title (flat single-bin vs. genuine multi-track).
  ripDiscRedumper =
    {
      name,
      system,
      device ? "/dev/sr0",
      speed ? 8,
      retries ? 100,
    }:
    let
      entry = datJson.${system}.${name};
      sanitizedName = lib.strings.sanitizeDerivationName name;
      rawArgs = "--title=${lib.escapeShellArg name} --device=${device} --speed=${toString speed} --retries=${toString retries}";
    in
    if entry ? tracks then
      let
        # One privileged physical read, not a FOD -- hardware-sourced, not
        # reproducible in the FOD sense, so this is just an ordinary
        # derivation. requiredSystemFeatures still gates it to a drive that
        # supports redumper's C2/subchannel reads.
        rawDump =
          pkgs.runCommand "disc-${sanitizedName}-rawdump"
            {
              requiredSystemFeatures = [ "redumper-drive" ];
              __noChroot = true;
            }
            ''
              ${flockBlock}
              ${doasResolve}
              mkdir -p "$out"
              "$doas" ${helper} --mode=redumper ${rawArgs} --out="$out" ${ownerArgs}
            '';

        trackFod =
          i: track:
          pkgs.runCommand "disc-${sanitizedName}-track-${toString (i + 1)}"
            {
              outputHash = track.sha1;
              outputHashAlgo = "sha1";
              outputHashMode = "flat";
            }
            ''
              cp ${rawDump}/track-${lib.fixedWidthNumber 2 (i + 1)}.bin "$out"
            '';
      in
      {
        cue =
          if entry ? cue then
            pkgs.runCommand "disc-${sanitizedName}-cue"
              {
                outputHash = entry.cue.sha1;
                outputHashAlgo = "sha1";
                outputHashMode = "flat";
              }
              ''
                cp ${rawDump}/disc.cue "$out"
              ''
          else
            null;
        bins = lib.imap0 trackFod entry.tracks;
      }
    else
      fetchToolOutput {
        name = "disc-${sanitizedName}-redumper";
        outputHash = entry.sha1;
        outputHashMode = "flat";
        extraAttrs = {
          outputHashAlgo = "sha1";
          requiredSystemFeatures = [ "redumper-drive" ];
          __noChroot = true;
        };
        script = ''
          ${flockBlock}
          ${doasResolve}
          tmp=$(mktemp -d)
          "$doas" ${helper} --mode=redumper ${rawArgs} --out="$tmp" ${ownerArgs}
          cp "$tmp/track-01.bin" "$out"
        '';
      };
}
