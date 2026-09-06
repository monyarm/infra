args:
let
  compressRom = import ./compressRom args;
in
{
  patchFile = import ./patchFile.nix args;
  patchZip = import ./patchZip.nix args;
}
// compressRom
