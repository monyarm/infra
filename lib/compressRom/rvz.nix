{ pkgs, getName, ... }:
# rvzconv.sh: GameCube/Wii disc images, dispatched via the ".gc.iso"/
# ".wii.iso" compound extensions (see default.nix's aliases) since a bare
# ".iso" alone can't say which console it's from.
extra: primary:
pkgs.runCommand "${getName primary}.rvz"
  {
    nativeBuildInputs = [ pkgs.dolphin-emu ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    dolphin-tool convert -f rvz -b 131072 -c lzma2 -l 9 -s -i "${primary}" -o "$out"
  ''
