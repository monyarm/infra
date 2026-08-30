{
  lib,
  pkgs,
  stdenv,
  fetchGitTree,
  fetchurl,
  sources,
  nodejs,
  pnpm,
  pnpmConfigHook,
  fetchPnpmDeps,
  makeWrapper,
  jq,
  gawk,
  writeShellScript,
  ...
}:

let
  # packages/cli: no lockfile of its own, uses repo-root pnpm-lock.yaml workspace
  cavemanSource = sources.claude.plugins.caveman;
  src = fetchGitTree (
    removeAttrs cavemanSource [
      "pnpmDepsHash"
      "pnpmWorkspace"
      "pnpmRemoveRootDependency"
    ]
  );
  version = cavemanSource.tag or "0-unstable-${cavemanSource.date}";
  pnpmWorkspaces = [ cavemanSource.pnpmWorkspace ];
  pnpmPackageFilter = pkgs.writeText "caveman-pnpm-package-normalization.jq" ''
    del(.dependencies[$package], .devDependencies[$package], .optionalDependencies[$package])
  '';
  pnpmLockFilter = pkgs.writeText "caveman-pnpm-lock-normalization.awk" ''
    BEGIN { root = 0; section = ""; skip = 0 }
    /^importers:$/ { print; in_importers = 1; next }
    in_importers && /^  [^ ].*:/ { root = ($0 == "  .:"); section = ""; skip = 0 }
    root && /^    (dependencies|devDependencies|optionalDependencies):$/ { section = 1; print; next }
    root && /^    [^ ].*:/ { section = 0; print; next }
    skip && /^[ ]{7}/ { next }
    { skip = 0 }
    root && section && /^[ ]{6}[^ ].*:/ { key = $0; sub(/^[ ]{6}/, "", key); sub(/:.*/, "", key); gsub(sprintf("%c", 34), "", key); gsub(sprintf("%c", 39), "", key); if (key == package) { skip = 1; next } }
    { print }
  '';
  normalizePnpm = writeShellScript "caveman-normalize-pnpm" ''
    set -e
    package=${lib.escapeShellArg cavemanSource.pnpmRemoveRootDependency}
    jq --arg package "$package" -f ${pnpmPackageFilter} package.json > package.json.tmp
    mv package.json.tmp package.json
    awk -v package="$package" -f ${pnpmLockFilter} pnpm-lock.yaml > pnpm-lock.yaml.tmp
    mv pnpm-lock.yaml.tmp pnpm-lock.yaml
  '';

  # what `caveman setup --install` would fetch -- do it at build time instead
  engineBinaries = {
    caveman-proxy = sources.claude.engine.caveman-proxy-linux-amd64;
    caveman-engine = sources.claude.engine.caveman-engine-linux-amd64;
    caveman-mcp = sources.claude.engine.caveman-mcp-linux-amd64;
    caveman-shrink = sources.claude.engine.caveman-shrink-linux-amd64;
    caveman-browse = sources.claude.engine.caveman-browse-linux-amd64;
    cavemem = sources.claude.engine.cavemem-linux-amd64;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "caveman-cli";
  inherit version src pnpmWorkspaces;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      pnpmWorkspaces
      ;
    fetcherVersion = 4; # 3 dropped for pnpm_11, and this nixpkgs pins pnpm 11
    # HEAD sometimes has root package.json ahead of pnpm-lock.yaml.
    prePnpmInstall = "${normalizePnpm}";
    hash = cavemanSource.pnpmDepsHash;
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
    jq
    gawk
  ];

  # Same package.json fix as pnpmDeps.prePnpmInstall above, needed again here since
  # pnpmConfigHook re-runs `pnpm install --frozen-lockfile` on this derivation's own
  # (unpatched) copy of src
  postPatch = "${normalizePnpm}";

  buildPhase = ''
    runHook preBuild
    pushd packages/cli
    npm run build
    popd
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/caveman-cli
    cp -r packages/cli/dist packages/cli/README.md packages/cli/LICENSE $out/lib/caveman-cli/

    mkdir -p $out/libexec/caveman-engine-bin
    ${lib.concatStrings (
      lib.mapAttrsToList (name: src': ''
        install -Dm755 ${fetchurl { inherit (src') url hash; }} $out/libexec/caveman-engine-bin/${name}
      '') engineBinaries
    )}

    makeWrapper ${nodejs}/bin/node $out/bin/caveman \
      --add-flags "$out/lib/caveman-cli/dist/index.js"
    makeWrapper ${nodejs}/bin/node $out/bin/cave \
      --add-flags "$out/lib/caveman-cli/dist/index.js"
    runHook postInstall
  '';

  # Engine binaries land at $out/libexec/caveman-engine-bin/ -- Claude module symlinks
  # them into ~/.caveman-cloud/bin/. Engine itself is BSL 1.1 (LICENSE.BSL), not MIT like
  # this CLI shim; local/self-hosted use (all this module does) is covered.
  meta = {
    description = "Caveman 2 CLI shim (`caveman`/`cave`) -- wraps coding agents through the local compression Proxy/Engine";
    homepage = "https://getcaveman.dev";
    license = lib.licenses.mit;
    mainProgram = "caveman";
    platforms = [ "x86_64-linux" ]; # only linux_amd64 engine binaries pinned so far
  };
})
