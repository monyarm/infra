{ pkgs, lib, ... }:
let

  json-sexpr-src = pkgs.fetchFromGitHub {
    owner = "ihalseide";
    repo = "json-sexpr";
    rev = "master";
    sha256 = "sha256-zAxJAgvewkkjNrqsmmh7fyqclLpJ+tNcRl56p8TarsE=";
  };

  json-sexpr-lib = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "json-sexpr-lib";
    version = "0.1.0";
    src = json-sexpr-src;
    buildInputs = [
      pkgs.python3Packages.setuptools
      pkgs.python3Packages.pyparsing
    ];
    preBuild = ''
      cat > setup.py << EOF
      from setuptools import setup

      setup(
          name = "sexpr",
          requires = ["pyparsing"],
          version = "${version}",
          py_modules=["sexpr"],
      )
      EOF
    '';
    build-system = with pkgs.python3Packages; [ setuptools ];
    pyproject = true;
    doCheck = false;
  };

  json-sexpr-script = pkgs.python3Packages.buildPythonPackage rec {
    pname = "json-sexpr-script";
    version = "0.1.0";
    src = json-sexpr-src;
    propagatedBuildInputs = [
      json-sexpr-lib
      pkgs.python3Packages.pyparsing
    ];
    preBuild = ''
      cat > setup.py << EOF
      from setuptools import setup

      setup(
          name = "json-sexpr-script",
          version = "${version}",
          py_modules=["json_sexpr"],
          scripts=["json_sexpr.py"],
      )
      EOF
    '';

    postInstall = ''
      # Rename the installed script to remove the .py extension
      mv $out/bin/json_sexpr.py $out/bin/json-sexpr
    '';
    build-system = with pkgs.python3Packages; [ setuptools ];
    pyproject = true;
    # The script itself doesn't have tests, but its dependency json-sexpr-lib does not have tests either.
    doCheck = false;
  };
in
rec {
  /**
    A generic function to convert a nested attribute set to an rc-style file.
    It recursively walks the attribute set, joining keys with a dot,
    and formats the final key-value pair on a new line.
  */
  toRCFile =
    attrs:
    let
      generateLines =
        path: attrs:
        lib.flatten (
          lib.mapAttrsToList (
            name: value:
            let
              newPath = path ++ [ name ];
            in
            if lib.isAttrs value then
              generateLines newPath value
            else
              let
                keyPath = lib.concatStringsSep "." newPath;
                formattedValue = if lib.isString value then ''"${value}"'' else toString value;
              in
              "${keyPath} ${formattedValue}"
          ) attrs
        );
    in
    lib.concatStringsSep "\n" (generateLines [ ] attrs);

  /**
    Converts a Nix attribute set to an S-expression string using json-sexpr.
  */
  toSexpr =
    attrs:
    let
      jsonFile = pkgs.writeText "input.json" (builtins.toJSON attrs);
    in
    builtins.readFile (
      pkgs.runCommand "json-to-sexpr-output" {
        buildInputs = [
          json-sexpr-lib
          pkgs.python3Packages.pyparsing
        ];
      } "${pkgs.python3}/bin/python ${json-sexpr-script}/bin/json-sexpr ${jsonFile} -s > $out"
    );

  toLisp = toSexpr;

  mkIniFormat =
    mkValueString: value:
    lib.generators.toINIWithGlobalSection
      {
        mkKeyValue = lib.generators.mkKeyValueDefault { inherit mkValueString; } "=";
      }
      {
        globalSection = value._global or { };
        sections = builtins.removeAttrs value [ "_global" ];
      };

  toINI = mkIniFormat (lib.generators.mkValueStringDefault { });

  toTOML = mkIniFormat (
    v: if lib.isString v then "'${v}'" else lib.generators.mkValueStringDefault { } v
  );

}
