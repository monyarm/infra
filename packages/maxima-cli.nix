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
  cargoLock = pkgs.writeText "Cargo.lock" sources.tools.maxima.cargoLock;

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

  # [patch.crates-io] in root Cargo.toml pulls flate2/async-compression from
  # ArmchairDevelopers git forks -- crane's own vendoring (importCargoLock
  # under the hood) needs an explicit hash per git dependency for these;
  # process_cargo computed them into sources.tools.maxima.cargoOutputHashes
  # via nix-prefetch-git at update-sources.py time. Passed straight to
  # buildPackage (not a separate vendorCargoDeps call assigned to
  # cargoVendorDir) so crane's own plumbing threads it through both the
  # buildDepsOnly and full-build passes consistently.
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
