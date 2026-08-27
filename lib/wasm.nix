{ pkgs, nixWasmRustPath, ... }:
let
  # crateDir's Cargo.toml has a nix-wasm-rust path dep, populated here from
  # the flake input. Content-addressed, recursive: a rustc/nix-wasm-rust/
  # toolchain bump that still produces byte-identical .wasm keeps the same
  # outPath, so dynamic.nix's toolPathsJSON (and with it every archive's
  # optimize-instantiate step) survives unrelated rebuilds of this module.
  buildWasmModule =
    { name, crateDir }:
    pkgs.stdenv.mkDerivation {
      pname = name;
      version = "0.1.0";
      src = crateDir;
      nativeBuildInputs = [
        pkgs.cargo
        pkgs.rustc
        pkgs.lld
      ];
      postPatch = ''
        cp -r ${nixWasmRustPath}/nix-wasm-rust ./nix-wasm-rust
        chmod -R u+w ./nix-wasm-rust
      '';
      buildPhase = ''
        export CARGO_HOME=$TMPDIR/cargo-home
        export CARGO_NET_OFFLINE=true
        mkdir -p "$CARGO_HOME"
        # --allow-undefined: Value FFI host functions resolve at wasm call time.
        export RUSTFLAGS="-C linker-flavor=wasm-ld -C linker=wasm-ld -C link-arg=--allow-undefined"
        cargo build --offline --release --target wasm32-unknown-unknown
      '';
      installPhase = ''
        mkdir -p $out
        cp target/wasm32-unknown-unknown/release/*.wasm $out/
      '';
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      allowSubstitutes = false;
    };

  mathModule = buildWasmModule {
    name = "nix-wasm-plugin-math";
    crateDir = ./wasm/math;
  };

  serializeModule = buildWasmModule {
    name = "nix-wasm-plugin-serialize";
    crateDir = ./wasm/serialize;
  };

  dispatchModule = buildWasmModule {
    name = "nix-wasm-plugin-dispatch";
    crateDir = ./wasm/dispatch;
  };
in
{
  inherit buildWasmModule;

  crc32 =
    str:
    builtins.wasm {
      path = "${mathModule}/nix_wasm_plugin_math.wasm";
      function = "crc32_string";
    } str;

  toKeyValues =
    attrs:
    builtins.wasm {
      path = "${serializeModule}/nix_wasm_plugin_serialize.wasm";
      function = "to_keyvalues";
    } attrs;

  toSexpr =
    value:
    builtins.wasm {
      path = "${serializeModule}/nix_wasm_plugin_serialize.wasm";
      function = "to_sexpr";
    } value;

  # See lib/misc.nix's resolveDispatchBatch for the Nix-side entries/files
  # shape this expects and the semantics it must stay faithful to.
  resolveDispatchBatch =
    input:
    builtins.wasm {
      path = "${dispatchModule}/nix_wasm_plugin_dispatch.wasm";
      function = "resolve_dispatch_batch";
    } input;
}
