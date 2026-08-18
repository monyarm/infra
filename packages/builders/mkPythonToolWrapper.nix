{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
}:
{
  pname,
  version,
  src,
  scripts,
  extraShare ? [ ],
  meta,
}:

stdenvNoCC.mkDerivation {
  inherit
    pname
    version
    src
    meta
    ;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/${pname}

    ${lib.concatMapStringsSep "\n" (script: ''
      mkdir -p "$out/share/${pname}/$(dirname "${script.path}")"
      cp "$src/${script.path}" "$out/share/${pname}/${script.path}"
    '') scripts}

    ${lib.concatMapStringsSep "\n" (item: ''
      cp -r "$src/${item}" "$out/share/${pname}/"
    '') extraShare}

    ${lib.concatMapStringsSep "\n" (script: ''
      makeWrapper ${python3}/bin/python3 $out/bin/${script.bin} \
        --add-flags "$out/share/${pname}/${script.path}"
    '') scripts}

    runHook postInstall
  '';
}
