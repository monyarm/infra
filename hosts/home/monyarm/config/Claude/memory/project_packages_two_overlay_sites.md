______________________________________________________________________

## name: packages-two-overlay-sites description: "packages/default.nix is instantiated from two separate call sites that must both get new args (craneLib, drowseSrc, etc.) or one silently gets null." metadata: node_type: memory type: project originSessionId: dd2c7cec-fbaa-4c55-bdcb-f638f1c66e5f

`packages/default.nix` (the `pkgs.callPackage`-over-every-file machinery) is
imported from **two independent places**, not one:

1. `flake.nix`'s `perSystem` — `legacyPackages = import ./packages { ... }`,
   the "normal", correctly-wired site. `packages.<name>` and
   `legacyPackages.<name>` both come from here.
1. `hosts/default.nix`'s `overlays` list — a **self-referential overlay**
   (`final: prev: import ../packages { pkgs = final; ... }`) that injects
   the same package set directly onto `pkgs` itself, so any code that does
   plain `pkgs.<packageName>` (e.g. a string interpolation like
   `"${pkgs.maxima-cli}/bin/..."` inside another `packages/*.nix` file)
   resolves through *this* instantiation, not site 1.

`lib/optimize/overlays.nix` has a third, similar self-referential overlay
(used to build `optimizePkgs` in `hosts/modules/lib.nix`).

**Why this matters:** each of these three call sites passes its own subset
of `packages/default.nix`'s optional args (`craneLib`, `drowseSrc`,
`nixWasmRustPath`, `niccupLib`, ...). `packages/default.nix` defaults every
one of them to `null` when omitted. A new arg added only at site 1 makes
`nix build .#<pkg>` succeed standalone while any *other* package that
references `pkgs.<pkg>` (not `legacyPackages.<pkg>`) crashes with `error: expected a set but found null: null`, deep in the referenced package's body
-- confusing because the failing package's own file looks correct and
builds fine in isolation.

**How to apply:** whenever a `packages/*.nix` file gains a new required
`callPackage`-supplied arg, grep for every place `import ../packages` or
`import packagesPath` appears (`hosts/default.nix`'s overlay,
`lib/optimize/overlays.nix`, `flake.nix`) and thread the new arg into all
of them, not just the one you're actively testing against.
