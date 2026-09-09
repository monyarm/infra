{ pkgs, ... }:
# Helper backing lib/fetchers/disc.nix's ripDisc/ripDiscContents/
# ripDiscRedumper. One script, mode-parameterized, rather than three
# separate doas grants -- see hosts/modules/config/doas.nix.
#
# Only --mode=redumper actually needs root: it sends raw SCSI generic
# commands needing CAP_SYS_RAWIO, which plain file permissions can't grant
# (confirmed against redumper's own docs). --mode=image/contents only need
# read access to the block device (an ACL grant, see .envrc, covers that)
# -- image reads it raw via ddrescue, contents extracts the filesystem via
# xorriso reading a local ddrescue copy, no `mount` syscall (and so no
# root) needed at all. disc.nix only wraps the redumper call in doas.
#
# doas's own `args` field can't pattern-match a variable per-title argv
# (it requires an exact full-argv match), so the real "only touch an
# optical drive, nothing else" enforcement happens here, not in doas.conf.
pkgs.writeShellApplication {
  name = "disc-rip-helper";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.util-linux
    pkgs.beep
    pkgs.redumper
    pkgs.ddrescue
    pkgs.xorriso
    pkgs.cdrtools
  ];
  text = ''
    # Data-CD .iso9660 size, in bytes, or empty if it can't be determined
    # (non-ISO9660 disc, unreadable TOC) -- same isoinfo fields
    # dvdrip.sh's get_disc_info uses. Discs that don't fill their full
    # capacity (e.g. Sam & Max Hit the Road's CD, ~1/3 full) otherwise
    # send ddrescue reading into the blank/lead-out region past the real
    # data, which is where it was observed stalling around 63% on an
    # otherwise clean disc.
    probe_data_size() {
      local info bs vs
      info=$(isoinfo -d -i "$1" 2>/dev/null) || { echo ""; return; }
      bs=$(printf '%s\n' "$info" | grep -oP '^Logical block size is: \K\d+' || true)
      vs=$(printf '%s\n' "$info" | grep -oP '^Volume size is: \K\d+' || true)
      if [ -n "$bs" ] && [ -n "$vs" ]; then
        echo $((bs * vs))
      else
        echo ""
      fi
    }

    mode="" title="" device="" out="" speed=8 retries=100 owner_uid="" owner_gid=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --mode=*) mode="''${1#*=}" ;;
        --title=*) title="''${1#*=}" ;;
        --device=*) device="''${1#*=}" ;;
        --out=*) out="''${1#*=}" ;;
        --speed=*) speed="''${1#*=}" ;;
        --retries=*) retries="''${1#*=}" ;;
        --owner-uid=*) owner_uid="''${1#*=}" ;;
        --owner-gid=*) owner_gid="''${1#*=}" ;;
        *) echo "disc-rip-helper: unknown argument: $1" >&2; exit 1 ;;
      esac
      shift
    done

    case "$mode" in
      image | contents | redumper) ;;
      *) echo "disc-rip-helper: --mode must be image, contents, or redumper" >&2; exit 1 ;;
    esac
    [[ "$device" =~ ^/dev/sr[0-9]+$|^/dev/sg[0-9]+$ ]] || {
      echo "disc-rip-helper: --device must be an optical drive (/dev/srN or /dev/sgN), got: $device" >&2
      exit 1
    }
    [ -n "$title" ] || { echo "disc-rip-helper: --title required" >&2; exit 1; }
    [ -n "$out" ] || { echo "disc-rip-helper: --out required" >&2; exit 1; }

    # Tried an auto-eject here for a hardware-independent signal, but
    # eject's udev/sysfs-based device resolution doesn't work against the
    # sandbox's minimal/synthetic /dev (confirmed: "devtmpfs: not found
    # mountpoint or device with the given name") -- not fixable without
    # __noChroot, not worth it just for this. The printed message below
    # (which streams live via nix-build's default log output) is the real
    # signal; beep is best-effort on top (silently no-ops without a PC
    # speaker, which most modern machines don't have).
    echo "=== disc-rip-helper: insert disc for: $title ==="
    while ! blockdev --getsize64 "$device" >/dev/null 2>&1; do
      beep -f 1000 -l 200 2>/dev/null || true
      sleep 5
    done
    echo "=== disc-rip-helper: disc detected, proceeding ==="

    case "$mode" in
      image)
        # ddrescue over dd: retries/skips bad sectors instead of dying on
        # the first read error -- matters on scratched/marginal discs. -d
        # (direct disc access, bypass kernel cache) is GNU ddrescue's own
        # documented recommendation for optical media, where cache
        # double-buffering can mask or worsen marginal reads. Mapfile
        # kept (not deleted) between passes: a second reverse-direction
        # (-R) pass only touches sectors the first pass still marks
        # unfinished -- some optical drives recover a sector reading it
        # from the other direction (different seek/laser approach) after
        # forward reads exhaust their retries.
        size=$(probe_data_size "$device")
        sizeArgs=()
        [ -n "$size" ] && sizeArgs=(-s "$size")
        rescue_log=$(mktemp)
        ddrescue -b 2048 -d -r "$retries" "''${sizeArgs[@]}" "$device" "$out" "$rescue_log"
        ddrescue -b 2048 -d -r "$retries" "''${sizeArgs[@]}" -R "$device" "$out" "$rescue_log" || true
        rm -f "$rescue_log"
        ;;
      contents)
        # ddrescue to a local raw copy first, then extract from that --
        # one fast sequential pass off the (slow, seek-heavy) optical
        # drive, same bad-sector retry as image mode gets, then extraction
        # re-reads off local disk instead of the drive. No `mount` syscall
        # either way, so no root needed here.
        #
        # xorriso over 7z: p7zip's ISO9660 reader is minimal and can
        # misparse structures near a damaged sector, over-reporting
        # errors past the actual damage; xorriso is the dedicated
        # ISO9660/Rock Ridge tool and fails precisely on what's actually
        # unreadable, which is what we want here -- masking that would
        # just hide real data loss.
        mkdir -p "$out"
        size=$(probe_data_size "$device")
        sizeArgs=()
        [ -n "$size" ] && sizeArgs=(-s "$size")
        raw=$(mktemp)
        rescue_log=$(mktemp)
        ddrescue -b 2048 -d -r "$retries" "''${sizeArgs[@]}" "$device" "$raw" "$rescue_log"
        ddrescue -b 2048 -d -r "$retries" "''${sizeArgs[@]}" -R "$device" "$raw" "$rescue_log" || true
        rm -f "$rescue_log"
        xorriso -indev "$raw" -osirrox on -extract / "$out"
        rm -f "$raw"
        ;;
      redumper)
        # Only mode needing root: raw SCSI generic access, and redumper's
        # own docs require the disc be unmounted first (unlike image/
        # contents, which read the block device directly regardless of
        # whether it's also mounted read-only elsewhere).
        umount "$device" 2>/dev/null || true
        mkdir -p "$out"
        # --drive intentionally omitted: redumper auto-detects the single
        # generic SCSI device on distros with a standard sysfs layout,
        # sidestepping the /dev/srN -> /dev/sgN mapping entirely.
        redumper disc --image-name="$title" --image-path="$out" \
          --speed="$speed" --retries="$retries"
        # Normalize to a predictable track-NN scheme -- don't trust
        # redumper's own multi-track naming to match redump DAT track
        # names; the per-track FOD split in disc.nix matches by position.
        # sort -V (not bash glob order, which is lexicographic and would
        # put "Track 10" before "Track 2"): numeric/natural sort so a
        # 10+ track disc still lands in physical track order.
        n=0
        while IFS= read -r f; do
          n=$((n + 1))
          mv "$f" "$out/track-$(printf '%02d' "$n").bin"
        done < <(find "$out" -maxdepth 1 -name '*.bin' | sort -V)
        for f in "$out"/*.cue; do
          [ -e "$f" ] || continue
          mv "$f" "$out/disc.cue"
        done
        ;;
    esac

    if [ -n "$owner_uid" ]; then
      chown -R "$owner_uid''${owner_gid:+:$owner_gid}" "$out"
    fi
  '';
}
