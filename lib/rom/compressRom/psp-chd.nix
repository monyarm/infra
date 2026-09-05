{
  pkgs,
  lib,
  getName,
  unwrapRom,
  ...
}:
# PSP-specific CHD path (pspchdconv.sh): DVD hunk size fixed at 2048 (the
# standard ISO9660 sector size), where the generic chd.nix DVD path (for
# plain .iso) leaves it at chdman's default -- preserving each script's
# original behavior rather than unifying them. Dispatched only for
# ".psp.iso" (see default.nix's aliases), so the input is already a real
# .iso, not a .cso -- no decompress step needed here. Always a bare src,
# never a named-parts attrset -- PSP isos never have siblings.
extra: input:
let
  primary = unwrapRom input;
  outName = "${getName primary}.chd";
  parentArg = lib.optionalString (extra != null) ''-op "${extra}"'';
  convertCmd = ''chdman createdvd -hs 2048 -i "${primary}" -o "$out" ${parentArg}'';
in
pkgs.runCommand outName
  {
    nativeBuildInputs = [ pkgs.mame-tools ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    ${convertCmd}
  ''
