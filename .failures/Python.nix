# This file implements a non-standard, impure method to symlink Python packages
# into the user's local site-packages directory, as per specific user request.
#
# WARNING: This code uses `builtins.readDir` on derivation outputs, which is an
# impure operation. It requires `allow-import-from-derivation = true;` in your
# nix.conf and will cause tools like `nix flake check` to fail.
# The standard, pure, and recommended approach is to use `pkgs.python3.buildEnv`.
{
  lib,
  pkgs,
  ...
}:

let
  #
  # Recursively collects all packages and their dependencies.
  collectAllPackages =
    pkgsList:
    let
      # The recursive part: for a single package, return itself plus its dependencies.
      collect =
        pkg:
        [ pkg ]
        ++ (if pkg ? "requiredPythonModules" then collectAllPackages pkg.requiredPythonModules else [ ]);
      uniquePkgs = lib.unique (lib.concatMap collect pkgsList);
    in
    # Exclude the python interpreter itself from the list of packages to be linked.
    lib.filter (pkg: pkg.pname != "python3" && pkg.pname != null) uniquePkgs;

  # This function generates the home.file configuration for a given list of
  # packages belonging to a specific python interpreter.
  linkPythonSitePackages =
    python: packages:
    let
      # Recursively gather all dependencies.
      allPackages = collectAllPackages packages;

      # Helper function to generate the home.file attrset for a single package.
      processPackage =
        pkg:
        let
          # This is the impure step that reads the contents of a package's
          # site-packages directory at evaluation time.
          sitePackagesContents = builtins.readDir "${pkg}/${python.sitePackages}";

          # Helper function to create a single home.file entry (name and value).
          createFileEntry =
            name: _type:
            lib.nameValuePair
              # The destination path is made dynamic using the python version.
              ".local/lib/${python.libPrefix}/site-packages/${name}"
              # The source is the specific file/folder within the package.
              { source = "${pkg}/${python.sitePackages}/${name}"; };
        in
        # Convert the attrset from readDir into a home.file attrset.
        lib.mapAttrs' createFileEntry sitePackagesContents;
    in
    # Merge the attribute sets generated from each package in the list.
    lib.foldl lib.recursiveUpdate { } (map processPackage allPackages);

  # New helper functions with shortened names as requested
  linkPython312 = packages: linkPythonSitePackages pkgs.python312 packages;
  linkPython313 = packages: linkPythonSitePackages pkgs.python313 packages;

in
{
  #
  # The new helper functions are called with inlined package lists, and the
  # results are merged and assigned to home.file.
  #
  home.file =
    (linkPython312 (
      with pkgs.python312Packages;
      [
        # Add your desired Python 3.12 packages here
        # e.g., requests
      ]
    ))
    // (linkPython313 (
      with pkgs.python313Packages;
      [
        # Add your desired Python 3.13 packages here
        guessit
        # e.g., wn
      ]
    ));
}
