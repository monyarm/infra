______________________________________________________________________

## name: feedback-packages-need-ellipsis-arg description: "Every packages/\*.nix file's formal argument list must end with `...` — packages/default.nix spreads all of customLib into every callPackage call, not just matched args." metadata: node_type: memory type: feedback originSessionId: b2bdba37-c049-4eae-84c8-5a53dba34006

Every new `packages/*.nix` file must end its formal argument attrset with `...`:

```nix
{
  lib,
  stdenv,
  ...
}:
```

**Why:** `packages/default.nix` calls `pkgs.callPackage (./. + "/${fileName}") ({ lib = extendedLib; inherit sources drowseSrc craneLib; } // customLib)`
— `customLib` (dozens of keys, e.g. `meta`) is spread into the **explicit args** passed to every
package, not just pulled from `pkgs`'s auto-scope. `callPackage`'s `intersectAttrs` filtering only
applies to the auto-scope; explicitly-passed args are NOT filtered against the function's formal
parameters. Without `...`, any package file errors with `function 'anonymous lambda' called with unexpected argument 'meta'` the moment it's callPackage'd, even though the file itself never
references `meta`. Confirmed empirically 2026-08-17 building 6 new packages (mmlc-dac-extractor,
mmxlc-rom-extractor, neogeo-rom-extractor, dotemu2mame, marchive-batch-tool, ree-rom-cryptor) — all
6 failed until `...` was added.

**How to apply:** Always end a new `packages/*.nix` formal-arg list with `...`, even if the file
declares every arg it needs explicitly. Existing files like `wadptr.nix` already do this — copy
that shape, don't drop the trailing `...` when writing a new one from scratch.
