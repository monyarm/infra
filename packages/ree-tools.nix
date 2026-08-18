{
  lib,
  stdenvNoCC,
  fetchGitTree,
  sources,
  mono,
  zstd,
  makeWrapper,
  ...
}:

# Merges ree-unpacker and ree-rom-cryptor: same upstream repo, two C#
# projects, always used together -- one derivation, two binaries on PATH.
#
# REE.Unpacker: pulls .mameac.2 ROM from .pak (CAS_STM_Release tag list),
# needs libzstd at runtime plus Projects/ dir colocated with the exe
# (reads relative to itself, not cwd).
#
# REE.Rom.Cryptor: decrypts .mameac.2 into MAME-loadable zip.
let
  src = fetchGitTree sources.tools.reePakTool;
in
stdenvNoCC.mkDerivation {
  pname = "ree-tools";
  version = sources.tools.reePakTool.date;

  inherit src;

  nativeBuildInputs = [
    mono
    makeWrapper
  ];

  # REE.Unpacker hardcodes Windows path separators (@"\") in a few spots for
  # output-dir handling and the Projects/ list lookup -- Mono/.NET on Linux
  # never treats backslash as a separator, so these need forward slashes.
  postPatch = ''
    substituteInPlace REE.Unpacker/REE.Unpacker/Program.cs \
      --replace-fail 'Path.GetDirectoryName(args[1]) + @"\" + Path.GetFileNameWithoutExtension(args[1]) + @"\";' \
                      'Path.GetDirectoryName(args[1]) + "/" + Path.GetFileNameWithoutExtension(args[1]) + "/";'
    substituteInPlace REE.Unpacker/REE.Unpacker/FileSystem/Package/PakUnpack.cs \
      --replace-fail 'm_FileName.Replace("/", @"\")' 'm_FileName.Replace("/", "/")'
    substituteInPlace REE.Unpacker/REE.Unpacker/FileSystem/Helpers/Utils.cs \
      --replace-fail 'm_Arg.EndsWith("\\")' 'm_Arg.EndsWith("/")' \
      --replace-fail 'm_Arg + @"\";' 'm_Arg + "/";'
    substituteInPlace REE.Unpacker/REE.Unpacker/FileSystem/Package/PakList.cs \
      --replace-fail '@"\Projects\"' '"/Projects/"'
  '';

  buildPhase = ''
    runHook preBuild
    ( cd REE.Unpacker/REE.Unpacker
      mcs -unsafe -optimize+ -out:REE.Unpacker.exe \
        -r:System.Net.Http.dll -r:System.Xml.Linq.dll -r:Microsoft.CSharp.dll \
        -r:System.Numerics.dll -r:Libs/System.Buffers.dll -r:Libs/Zstandard.Net.dll \
        $(find . -name '*.cs') )
    ( cd REE.Rom.Cryptor/REE.Rom.Cryptor
      mcs -unsafe -optimize+ -out:REE.Rom.Cryptor.exe \
        -r:System.Net.Http.dll -r:System.Xml.Linq.dll -r:Microsoft.CSharp.dll \
        $(find . -name '*.cs') )
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/ree-tools $out/bin
    cp REE.Unpacker/REE.Unpacker/REE.Unpacker.exe \
       REE.Unpacker/REE.Unpacker/Libs/Zstandard.Net.dll \
       REE.Unpacker/REE.Unpacker/Libs/System.Buffers.dll \
       $out/lib/ree-tools/
    ln -s ${zstd.out}/lib/libzstd.so $out/lib/ree-tools/libzstd.dll
    cp -r Projects $out/lib/ree-tools/Projects
    cp REE.Rom.Cryptor/REE.Rom.Cryptor/REE.Rom.Cryptor.exe $out/lib/ree-tools/

    makeWrapper ${mono}/bin/mono $out/bin/REE.Unpacker \
      --add-flags "$out/lib/ree-tools/REE.Unpacker.exe" \
      --run "cd $out/lib/ree-tools" \
      --set LD_LIBRARY_PATH ${zstd.out}/lib
    makeWrapper ${mono}/bin/mono $out/bin/REE.Rom.Cryptor \
      --add-flags "$out/lib/ree-tools/REE.Rom.Cryptor.exe"
    runHook postInstall
  '';

  meta = {
    description = "Unpacks and decrypts RE Engine .pak/.mameac.2 archives (Capcom Arcade Stadium/2nd Stadium et al)";
    homepage = "https://github.com/Ekey/REE.PAK.Tool";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
