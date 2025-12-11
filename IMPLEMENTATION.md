# Generic Plan for Integrating Dotfile Directories into Home Manager

This document outlines a generic process for integrating a dotfile directory from `~/.dotfiles/Home/` into a Nix `home-manager` configuration. The goal is to manage these dotfiles declaratively, consolidate common configurations where appropriate, and mark the original directory as handled.

## Prerequisites

- A Nix `home-manager` setup is in place, with a `flake.nix` and `default.nix` (or similar structure) in `~/.homemanager`.
- The `default.nix` in `~/.homemanager` exposes `dirs` (containing `HOME`, `HM`, `config`) and `mkOutOfStoreSymlink` in its `_module.args`.
- The target dotfile directory is initially located at `~/.dotfiles/Home/<DOTFILE_NAME>`.

## Steps

1. **Analyze the Target Dotfile Directory:**

   - Examine the structure and contents of `~/.dotfiles/Home/<DOTFILE_NAME>`.
   - Identify subdirectories and files that represent distinct configurations (e.g., different versions of an application, or different components).
   - Identify any files or subdirectories that are *identical* across multiple distinct configurations within `<DOTFILE_NAME>` (if applicable, for future consolidation).

1. **Create a Dedicated Home Manager Module:**

   - Create a new directory for the module: `~/.homemanager/config/<DOTFILE_NAME>`.
   - Create a `default.nix` file inside this new directory: `~/.homemanager/config/<DOTFILE_NAME>/default.nix`. This file will contain the `home-manager` configuration for the dotfile.

1. **Move Existing Dotfile Configurations into the `.homemanager` Structure:**

   - Move the contents of `~/.dotfiles/Home/<DOTFILE_NAME>/<SUB_DIR_OR_FILE>` to `~/.homemanager/config/<DOTFILE_NAME>/<SUB_DIR_OR_FILE>`. This step applies to all relevant subdirectories and files that will be managed by the new module.

1. **Define Home Manager Configurations in the Module's `default.nix`:**

   - The `default.nix` file created in Step 2 will use `home.file` entries to manage the dotfiles.

   - For each distinct configuration (e.g., each IDE version in the JetBrains example), define a `home.file` entry.

   - The *target path* for `home.file` should be the desired location in the user's home directory (e.g., `.CLion2018.3`).

   - The *source path* for `home.file` will use `mkOutOfStoreSymlink` to point to the *new location* of the dotfile directory within `~/.homemanager/config/<DOTFILE_NAME>`.

   - **Conceptual `default.nix` content:**

     ```nix
     { config, pkgs, dirs, mkOutOfStoreSymlink, ... }:

     in
     {
       # Example for a single configuration (e.g., .CLion2018.3)
       home.file."<TARGET_PATH_IN_HOME_DIR>" = {
         source = mkOutOfStoreSymlink "${dirs.config}/<DOTFILE_NAME>/<SUB_DIR_OR_FILE_TO_SYMLINK>";
       };

       # If there are multiple distinct configurations (like JetBrains IDEs):
       # home.file.".CLion2018.3" = {
       #   source = mkOutOfStoreSymlink "${dirs.config}/<DOTFILE_NAME>/.CLion2018.3";
       # };
       # home.file.".PhpStorm2019.1" = {
       #   source = mkOutOfStoreSymlink "${dirs.config}/<DOTFILE_NAME>/.PhpStorm2019.1";
       # };
       # home.file.".WebStorm2019.1" = {
       #   source = mkOutOfStoreSymlink "${dirs.config}/<DOTFILE_NAME>/.WebStorm2019.1";
       # };
     }
     ```

1. **Integrate the New Module into the Main Home Manager Configuration:**

   - Add `./config/<DOTFILE_NAME>` to the `imports` list in `~/.homemanager/default.nix`.

1. **Final Cleanup:**

   - Rename the original dotfile directory: `~/.dotfiles/Home/<DOTFILE_NAME>` to `~/.dotfiles/Home/<DOTFILE_NAME>.old`. This marks it as handled and prevents conflicts.
