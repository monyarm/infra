args:
let
  compressRom = import ./compressRom args;
in
{
  patchFile = import ./patchFile.nix args;
}
// compressRom
