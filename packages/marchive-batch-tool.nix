{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  icu,
  openssl,
  zlib,
  curl,
  krb5,
  dotnetCorePackages,
  ...
}:

let
  # bundled netcoreapp2.2 (EOL 2019) self-contained CoreCLR can't init on
  # current glibc/kernel -- retarget onto nixpkgs' maintained runtime.
  runtime = dotnetCorePackages.runtime_8_0;
in
# GitHub Releases binary asset, not a git checkout -- update-sources.py's
# git fetcher can't reach it, so fetched directly instead of via
# sources.toml/fetchGitTree.
stdenv.mkDerivation {
  pname = "marchive-batch-tool";
  version = "unstable-2023-11-23";

  src = fetchurl {
    url = "https://github.com/farmerbb/RED-Project/releases/download/tools/MArchiveBatchTool-linux-x64.zip";
    sha256 = "0c4av3qpgxrr9jjwb4pp0fwz99n93wfzr90v24qqv0wgcsgbfpm1";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    icu
    openssl
    zlib
    curl
    krb5
  ];

  sourceRoot = ".";

  # liblttng-ust.so.0 is coreclr's optional tracing provider (dlopen'd,
  # no-op if absent) -- nixpkgs only ships the ABI-incompatible .so.1.
  autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/marchive-batch-tool
    cp -r MArchiveBatchTool-linux-x64/. $out/lib/marchive-batch-tool/
    cd $out/lib/marchive-batch-tool

    # drop every bundled file the target framework already ships, forcing
    # the loader to resolve them there instead of the vendored copies
    framework=(${runtime}/share/dotnet/shared/Microsoft.NETCore.App/*)
    framework="''${framework[0]}"
    for f in *.dll *.so; do
      [ -e "$framework/$f" ] && rm -f "$f"
    done

    # hostpolicy resolves these via a local-dir probe (skips the deps.json
    # lookup other natives use); autoPatchelf needs libmscordaccore.so's
    # NEEDED entry satisfied locally too, since it can't see the framework dir
    for f in libcoreclr.so libclrjit.so libhostpolicy.so libmscordaccore.so; do
      ln -sf "$framework/$f" "$f"
    done

    # switch to framework-dependent so it resolves against $framework
    # instead of its (now-deleted) bundled runtime
    cat > MArchiveBatchTool.runtimeconfig.json <<EOF
    {
      "runtimeOptions": {
        "tfm": "netcoreapp2.2",
        "framework": { "name": "Microsoft.NETCore.App", "version": "2.2.0" },
        "rollForward": "LatestMajor",
        "configProperties": {
          "System.Reflection.Metadata.MetadataUpdater.IsSupported": false
        }
      }
    }
    EOF

    chmod +x MArchiveBatchTool
    mkdir -p $out/bin
    # native apphost's self-contained mode is baked in at publish time,
    # runtimeconfig edits can't retarget it -- launch the .dll via dotnet instead
    makeWrapper "${runtime}/bin/dotnet" $out/bin/MArchiveBatchTool \
      --add-flags "$out/lib/marchive-batch-tool/MArchiveBatchTool.dll"
    runHook postInstall
  '';

  meta = {
    description = "Unpacks MArchive-format alldata.bin/alldata.psb.m game archives (Capcom/Konami/Namco legacy collections)";
    homepage = "https://github.com/farmerbb/RED-Project/wiki";
    license = lib.licenses.unfree; # bundles Newtonsoft.Json/SharpZipLib etc. under their own licenses
    mainProgram = "MArchiveBatchTool";
    platforms = [ "x86_64-linux" ];
  };
}
