{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
  makeWrapper,
  zip,
  ...
}:

let
  src = fetchurl {
    url = "https://gist.githubusercontent.com/cxx/81b9f45eb5b3cb87b4f3783ccdf8894f/raw/5b5e677d2d904071888fe7ea08a83c50ab9ba1cb/dotemu2mame.js";
    sha256 = "0afi54zqkbxfm4fcbzv31z1v3z759q1ylk1pvbpzghymcra75r8i";
  };
in
stdenvNoCC.mkDerivation {
  pname = "dotemu2mame";
  version = "unstable-2023-04-10";

  inherit src;
  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  # `dotemu2mame <romdir>`, run from wherever the output zip(s) should land;
  # game is auto-detected from marker files present in romdir.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/dotemu2mame --add-flags "${src}" \
      --prefix PATH : "${lib.makeBinPath [ zip ]}"
    runHook postInstall
  '';

  meta = {
    description = "Converts DotEmu release game data into MAME-loadable romset zips";
    homepage = "https://github.com/farmerbb/RED-Project/wiki/Raiden-Legacy";
    license = lib.licenses.cc-by-sa-40;
    platforms = lib.platforms.unix;
  };
}
