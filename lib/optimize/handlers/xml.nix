{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# xmllint --noblanks correctly tells ignorable inter-element whitespace
# apart from meaningful text-node whitespace (verified: a whitespace-only
# <tspan> sitting next to real text, and a whitespace-only leaf <text>,
# both survive; only pure indentation between tags gets stripped) -- safe
# for well-formed XML and, since SVG is XML, for SVG too. --nonet: avoids
# any external-DTD fetch attempt in the sandbox. May add a missing
# `<?xml version="1.0"?>` declaration -- standard-compliant, not touched
# further.
#
# Real-world HTML and PHP were tested against this and rejected: HTML's
# unclosed void elements (<br>, <img>) break strict well-formedness, and a
# .php file isn't a single-root-element XML document even when its
# <?php ?> tags balance -- both just fail to parse here (safe passthrough
# via the guard below, but zero benefit), so they aren't routed through
# this handler.
{
  handler =
    src:
    derivation {
      name = "${getName src}-noblanks";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
            export PATH=${pkgs.coreutils}/bin:${pkgs.libxml2}/bin
          xmllint --noblanks --nonet "${src}" > tmp.out || rm -f tmp.out
          ${guardSizeTail "tmp.out" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [
    "xml"
    "svg"
  ];
}
