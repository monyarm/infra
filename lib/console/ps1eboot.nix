# PS1 disc(s) -> PSP EBOOT.PBP, via PSXPackager.
#
# Single disc: pass one source. Multi-disc: pass several in play order --
# psxpackager merges them into ONE EBOOT.PBP (an .m3u drives the disc list),
# which is how the PSP stores multi-disc titles. Output is a directory holding
# a single EBOOT.PBP, so it drops straight into a homebrew `package`.
#
# `discs` is a list of derivations/paths, each a directory holding one PS1 disc
# (.cue + .bin/.iso, or a bare image). `entries` is the matching m3u filename
# for each disc, in the same order -- the filename as it sits in that disc
# directory. PSXPackager resolves m3u entries relative to the m3u's own dir,
# so everything is staged into one directory first.
{
  lib,
  pkgs,
  psxpackager,
}:

let
  inherit (lib) concatStringsSep;
in
rec {
  mkPs1Eboot =
    {
      name,
      discs,
      entries,
      # psxpackager deflate level, 0-9 (default 5).
      level ? 5,
    }:
    assert builtins.length discs > 0 || builtins.trace "mkPs1Eboot: empty disc list" false;
    assert
      builtins.length discs == builtins.length entries
      || builtins.trace "mkPs1Eboot: discs/entries length mismatch" false;
    pkgs.runCommand "ps1eboot-${name}" { nativeBuildInputs = [ psxpackager ]; } ''
      mkdir -p build
      cd build

      # Stage all discs into one dir so the m3u's bare filenames resolve.
      # --no-preserve=mode keeps the read-only store perms off the build dir.
      ${concatStringsSep "\n" (map (d: "cp -r --no-preserve=mode ${d}/. .") discs)}
      cat > "${name}.m3u" <<'M3UEOF'
      ${concatStringsSep "\n" entries}
      M3UEOF

      psxpackager -i "${name}.m3u" -o . -l ${toString level}

      # psxpackager names the PBP after the .m3u; normalise to EBOOT.PBP so it
      # matches the card layout the resource model expects.
      pbp=$(ls *.pbp *.PBP 2>/dev/null | head -1)
      [ -n "$pbp" ] || { echo "ps1eboot: no PBP produced" >&2; exit 1; }
      mkdir -p "$out"
      cp "$pbp" "$out/EBOOT.PBP"
    '';
}
