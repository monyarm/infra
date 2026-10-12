# Destination path validation for console file trees.
#
# Only strict relative POSIX paths are accepted. Anything that could escape the
# mounted card, collide with the deployment control plane, or behave
# ambiguously on FAT32 is rejected at evaluation time.
{ lib }:

let
  inherit (lib) hasPrefix splitString;

  # builtins.match anchors the WHOLE string, so wrap in .* to test "contains".
  # Nix has no \xNN escape, so control chars come from the real \n \r \t
  # escapes; the rest are literal inside a bracket expression.
  illegalChars = ".*[\"<>|:?*\n\r\t\\\\].*";

  hasControlOrIllegal = path: builtins.match illegalChars path != null;
in
rec {
  # Reserved for deployment metadata (generations, manifests, journals).
  reservedDir = ".psp-nix";

  isReserved = path: hasPrefix "${reservedDir}/" path;

  # Splits on "/" and rejects empty components, so "a//b", "a/", and "/a" all
  # fail here rather than silently normalizing.
  components = path: splitString "/" path;

  describeViolation =
    path:
    let
      cs = components path;
    in
    if path == "" then
      "path is empty"
    else if hasPrefix "/" path then
      "path is absolute"
    else if hasControlOrIllegal path then
      "path contains a control or FAT32-illegal character"
    else if lib.hasInfix "\\" path then
      "path contains a backslash"
    else if builtins.elem "" cs then
      "path contains an empty component (double or trailing slash)"
    else if builtins.elem "." cs then
      "path contains a '.' component"
    else if builtins.elem ".." cs then
      "path contains a '..' component"
    else if isReserved path then
      "path is inside the reserved '${reservedDir}/' directory"
    else
      null;

  # Throws naming the offending path and the specific rule it broke.
  validate =
    path:
    let
      violation = describeViolation path;
    in
    if violation != null then
      throw "console: invalid destination path '${path}': ${violation}"
    else
      true;

  # True when `parent` is a strict component-wise ancestor of `child`, which
  # would make one declaration land on top of another.
  isAncestorOf =
    parent: child:
    let
      pc = components parent;
      cc = components child;
    in
    builtins.length pc < builtins.length cc
    && builtins.all (i: builtins.elemAt cc i == builtins.elemAt pc i) (
      builtins.genList (x: x) (builtins.length pc)
    );

  # Guards normalize(): no destination may be an ancestor of another.
  assertNoAncestorConflicts =
    paths:
    let
      offenders = builtins.filter (a: builtins.any (b: a != b && isAncestorOf a b) paths) paths;
      conflict = if offenders == [ ] then null else builtins.head offenders;
    in
    if conflict != null then
      throw "console: destination '${conflict}' collides with a path nested beneath it"
    else
      true;
}
