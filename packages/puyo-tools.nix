{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchGitTree,
  sources,
  ...
}:

let
  src = fetchGitTree sources.tools.puyoTools;
  inherit (sources.tools.puyoTools) dotnetSdk dotnetRuntime;
in
buildDotnetModule {
  pname = "puyo-tools-cli";
  version = sources.tools.puyoTools.tag;
  inherit src;

  projectFile = "src/PuyoTools.App.Cli/PuyoTools.App.Cli.csproj";
  nugetDeps = builtins.toFile "puyo-tools-nuget-deps.json" sources.tools.puyoTools.nugetDeps;

  dotnet-sdk = dotnetCorePackages.${dotnetSdk};
  dotnet-runtime = dotnetCorePackages.${dotnetRuntime};

  meta = {
    description = "CLI for Puyo Tools - SEGA compression/archives/textures (PRS, LZ, etc.)";
    homepage = "https://github.com/nickworonekin/puyotools";
    license = lib.licenses.mit;
    mainProgram = "PuyoToolsCli";
    platforms = lib.platforms.linux;
  };
}
