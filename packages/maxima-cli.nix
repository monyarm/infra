{
  lib,
  pkgs,
  fetchGitTree,
  sources,
  craneLib,
  ...
}:
let
  # cargoLock/cargoOutputHashes are process_cargo's output, merged into this
  # same [git] source entry by update-sources.py -- not git-fetch params.
  # fetchGitTree forwards unknown attrs straight into a raw `derivation {}`
  # call as env vars, so cargoOutputHashes (a nested attrset) must be
  # stripped here or it fails to coerce to a string.
  maximaSrc = fetchGitTree (
    removeAttrs sources.tools.maxima [
      "cargoLock"
      "cargoOutputHashes"
    ]
  );

  # sources.tools.maxima.cargoLock is generated at update-sources.py time
  # (see [cargo] in sources.toml / process_cargo there) -- no Cargo.lock
  # upstream to build from, and `cargo generate-lockfile` needs real network
  # access no nix sandbox grants. Overlay it onto the fetched tree before
  # handing off to crane, same shape as minijson.nix's combinedSrc
  # overlaying despacerSrc.
  cargoLock = builtins.toFile "Cargo.lock" sources.tools.maxima.cargoLock;

  combinedSrc = pkgs.runCommand "maxima-cli-combined-src" { } ''
    cp -r --no-preserve=mode "${maximaSrc}" "$out"
    chmod -R u+w "$out"
    cp "${cargoLock}" "$out/Cargo.lock"
  '';

  version = "0-unstable-${sources.tools.maxima.date}";
in
craneLib.buildPackage {
  pname = "maxima-cli";
  inherit version;
  src = combinedSrc;

  outputHashes = sources.tools.maxima.cargoOutputHashes;

  # maxima-resources's build.rs (prost-build, for its GRPC bindings) shells
  # out to protoc.
  nativeBuildInputs = [ pkgs.protobuf ];

  # maxima-ui/maxima-tui pull in GUI toolkits (egui) we don't need for this
  # fetcher -- build only the maxima-cli workspace member.
  cargoExtraArgs = "-p maxima-cli";
  doCheck = false;

  # maxima-lib/src/lib.rs unconditionally sets #![feature(type_ascription)],
  # a nightly-only attribute -- upstream targets nightly rustc. Unlocks it on
  # our stable-channel rustc instead of pulling in a whole nightly toolchain.
  env.RUSTC_BOOTSTRAP = "1";

  meta = {
    description = "CLI frontend for Maxima, an open-source Origin/EA Desktop client";
    homepage = "https://github.com/ArmchairDevelopers/Maxima";
    license = lib.licenses.gpl3Only;
    mainProgram = "maxima-cli";
    platforms = lib.platforms.linux;
  };
}
