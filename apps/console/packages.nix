# Console (PSP memory card) deployment packages.
#
# One library tree, one entry point. The three CLIs derive their subcommand from
# argv[0], so no store paths are baked into generated scripts.
{
  lib,
  pkgs,
  python3,
}:

let
  library = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./__init__.py
      ./__main__.py
      ./cli.py
      ./deploy.py
    ];
  };

  mkTool =
    name:
    pkgs.stdenv.mkDerivation {
      inherit name;
      src = library;
      nativeBuildInputs = [ python3 ];
      dontBuild = true;
      strictDeps = true;
      installPhase = ''
        mkdir -p "$out/bin" "$out/lib/console"
        for module in __init__ __main__ cli deploy; do
          install -Dm644 ${library}/''$module.py "$out/lib/console/$module.py"
        done
        cat > "$out/bin/${name}" <<WRAPPER
        #!${python3}/bin/python3
        import os, sys
        sys.path.insert(0, "$out/lib")
        from console.__main__ import main
        raise SystemExit(main())
        WRAPPER
        chmod +x "$out/bin/${name}"
      '';
      meta = {
        mainProgram = name;
        description = "Declarative PSP memory-card tool";
      };
    };
in
{
  psp-diff = mkTool "psp-diff";
  psp-apply = mkTool "psp-apply";
  psp-size = mkTool "psp-size";
}
