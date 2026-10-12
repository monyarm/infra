{
  lib,
  stdenv,
  fetchFromGitHub,
  mkNugetDeps,
  dotnet-sdk_8,
  makeWrapper,
  dotnetCorePackages,
  ...
}:

let
  version = "1.7.0";

  # ponytail: hashes hand-pinned -- update-sources.py has no [nuget] fetcher.
  # Bump with: nix-prefetch-url https://www.nuget.org/api/v2/package/<p>/<v>
  # Add a fetcher when a second NuGet package shows up.
  deps = mkNugetDeps {
    name = "psxpackager-deps";
    nugetDeps =
      { fetchNuGet }:
      [
        (fetchNuGet {
          pname = "CommandLineParser";
          version = "2.9.1";
          hash = "sha256-ApU9y1yX60daSjPk3KYDBeJ7XZByKW8hse9NRZGcjeo=";
        })
        (fetchNuGet {
          pname = "SharpCompress";
          version = "0.48.1";
          hash = "sha256-Y1lH1TrxBua3Ux6trRUQGeSfYjE3qld6TQDz/ABy6Ws=";
        })
        (fetchNuGet {
          pname = "ZstdSharp.Port";
          version = "0.7.4";
          hash = "sha256-z39r5ekafRbZAsKbOtAlL7ymW5SLosb0NUlStqvPBwE=";
        })
        (fetchNuGet {
          pname = "BunLabs.NAudio.Flac";
          version = "2.0.1";
          hash = "sha256-ezjeQLTnmUGzzgMqto32Dl2uHIPrSPLKV7r5UIh2R98=";
        })
        (fetchNuGet {
          pname = "SharpZipLib";
          version = "1.4.2";
          hash = "sha256-/giVqikworG2XKqfN9uLyjUSXr35zBuZ2FX2r8X/WUY=";
        })
        # transitive
        (fetchNuGet {
          pname = "NAudio.Core";
          version = "2.0.0";
          hash = "sha256-rD5ubdSgpufNjNyCerO0N5Gg2brUMhjEOL5qaNwFhBM=";
        })
        (fetchNuGet {
          pname = "Microsoft.Bcl.AsyncInterfaces";
          version = "8.0.0";
          hash = "sha256-9aWmiwMJKrKr9ohD1KSuol37y+jdDxPGJct3m2/Bknw=";
        })
        (fetchNuGet {
          pname = "System.Text.Encoding.CodePages";
          version = "8.0.0";
          hash = "sha256-fjCLQc1PRW0Ix5IZldg0XKv+J1DqPSfu9pjMyNBp7dE=";
        })
      ];
  };
in
# Built from source rather than the release tarball: the shipped binary is a
# self-contained single-file bundle, and patchelf resizing the ELF breaks its
# embedded bundle ("Arithmetic overflow while reading bundle"). Framework-
# dependent publish keeps loose DLLs, which `dotnet` loads fine.
stdenv.mkDerivation {
  pname = "psxpackager";
  inherit version;

  src = fetchFromGitHub {
    owner = "RupertAvery";
    repo = "PSXPackager";
    rev = "999cd52ba01df4c21afc52f68ae3ebf95db94065";
    hash = "sha256-FOx57+3VUGgwobFMkfza16fkChB0HUXm4/qvzQU8AZY=";
  };

  nativeBuildInputs = [
    dotnet-sdk_8
    deps
    makeWrapper
  ];

  # Repo-root-relative paths; the GUI/audio/test projects are never referenced.
  buildPhase = ''
    runHook preBuild

    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

    # Restore is driven entirely by the pinned nugetDeps set. Single-file must
    # be off at restore too: PublishSingleFile=true pulls in ILLink.Tasks,
    # which is not in the pinned set and cannot be fetched offline.
    dotnet restore PSXPackager/PSXPackager-linux.csproj \
      --no-cache \
      -p:RestorePackagesPath=deps \
      -p:PublishSingleFile=false \
      -p:PublishTrimmed=false

    # Framework-dependent + no single-file => loose DLLs we can wrap.
    dotnet publish PSXPackager/PSXPackager-linux.csproj \
      -c Release \
      --no-restore \
      -o publish \
      -p:SelfContained=false \
      -p:PublishSingleFile=false \
      -p:PublishTrimmed=false \
      -p:InvariantGlobalization=true

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/psxpackager
    cp -r publish/. $out/lib/psxpackager/
    mkdir -p $out/lib/psxpackager/Resources
    cp Popstation.Database/Resources/gameInfo.db $out/lib/psxpackager/Resources/gameInfo.db

    # ICSharpCode.Decompiler and SharpCompress read $ORIGIN for sibling payloads.
    makeWrapper ${dotnetCorePackages.runtime_8_0}/bin/dotnet $out/bin/psxpackager \
      --add-flags "$out/lib/psxpackager/psxpackager.dll"

    runHook postInstall
  '';

  # dotnet writes NuGet/build caches under HOME; keep them out of $out.
  preFixup = ''
    find $out -type f -name '*.json' -path '*obj*' -delete 2>/dev/null || true
  '';

  meta = {
    description = "Converts PlayStation 1 disc images to PSP-compatible EBOOT.PBP and back";
    homepage = "https://github.com/RupertAvery/PSXPackager";
    license = lib.licenses.mit;
    mainProgram = "psxpackager";
    platforms = [ "x86_64-linux" ];
  };
}
