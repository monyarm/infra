{
  lib,
  pkgs,
  dirs,
  mkOutOfStoreSymlink,
  resolved, # name -> { components; instance; resourcePackOrder; }, from resolveGame
  resolvedInstances, # name -> instance (resolved's .instance, for callers that don't need resourcePackOrder)
  sharedLibraries, # Maven path -> drv, deduped union of every instance's prism-component libraries
  ...
}:
with lib;
{
  # Deploys every resolved instance: Steam registration, per-file xdg.dataFile
  # symlinks (mods/resourcepacks/datapacks/extraSymlinkFiles are always
  # store-authoritative; config/saves/logs/options.txt are out-of-store,
  # runtime-mutable), and the two activation scripts that reconcile config/
  # against modpack updates and patch options.txt's resourcePacks line.
  programs.steam.games = mapAttrs' (
    name: _instanceDrv:
    nameValuePair name {
      inherit name;
      game = name;
      launcher = {
        package = pkgs.prismlauncher;
        args = [ "-l" ];
      };
      workingDirectory = "${dirs.hmConfig}/PrismLauncher/instances/${name}";
    }
  ) resolvedInstances;

  xdg.dataFile =
    foldlAttrs (
      acc: name: r:
      let
        inst = r.instance;
        base = "PrismLauncher/instances/${name}";
        fileEntries =
          subdir: fs:
          listToAttrs (
            map (f: nameValuePair "${base}/.minecraft/${subdir}/${f.name}" { source = f.path; }) fs
          );
      in
      acc
      // {
        "${base}/instance.cfg".source = "${inst.instanceBase}/instance.cfg";
        "${base}/mmc-pack.json".source = "${inst.instanceBase}/mmc-pack.json";
        "${base}/patches".source = "${inst.instanceBase}/patches";
        "${base}/.minecraft/config".source =
          mkOutOfStoreSymlink "${dirs.hmConfig}/${base}/.minecraft/config";
        "${base}/.minecraft/saves".source = mkOutOfStoreSymlink "${dirs.hmConfig}/${base}/.minecraft/saves";
        "${base}/.minecraft/logs".source = mkOutOfStoreSymlink "${dirs.hmConfig}/${base}/.minecraft/logs";
        "${base}/.minecraft/options.txt".source =
          mkOutOfStoreSymlink "${dirs.hmConfig}/${base}/.minecraft/options.txt";
      }
      // fileEntries "mods" inst.modFiles
      // fileEntries "resourcepacks" inst.resourcePackFiles
      // fileEntries "datapacks" inst.datapackFiles
      // listToAttrs (
        map (f: nameValuePair "${base}/.minecraft/${f.path}" { inherit (f) source; }) inst.extraSymlinkFiles
      )
    ) { } resolved
    // mapAttrs' (
      path: drv: nameValuePair "PrismLauncher/libraries/${path}" { source = drv; }
    ) sharedLibraries;

  home.activation.minecraftMutableContent = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let
      # config/ reconciliation: reseed a file only if it's unmodified since
      # the last deploy (tracked via a per-file hash sidecar); never clobber
      # an edited file -- write the new version alongside as <file>.nix-new
      # and warn instead. ponytail: whole-file hash granularity, not a real
      # 3-way content merge -- upgrade only if .nix-new conflicts turn out
      # to be frequent in practice.
      reseedFn = ''
        nix_minecraft_reseed_config() {
          local seed="$1" destf="$2" statefile="$3"
          mkdir -p "$(dirname "$destf")" "$(dirname "$statefile")"
          local newhash
          newhash="$(sha256sum "$seed" | cut -d' ' -f1)"
          if [ ! -e "$destf" ]; then
            cp "$seed" "$destf"; chmod u+w "$destf"
            echo "$newhash" > "$statefile"
            return 0
          fi
          local curhash lasthash
          curhash="$(sha256sum "$destf" | cut -d' ' -f1)"
          lasthash=""
          [ -f "$statefile" ] && lasthash="$(cat "$statefile")"
          if [ "$curhash" = "$newhash" ]; then
            echo "$newhash" > "$statefile"
          elif [ "$curhash" = "$lasthash" ]; then
            cp "$seed" "$destf"; chmod u+w "$destf"
            echo "$newhash" > "$statefile"
          else
            cp "$seed" "$destf.nix-new"
            echo "minecraft: $destf changed locally and in the nix config -- wrote new version to $destf.nix-new, merge by hand." >&2
          fi
        }
      '';
      perGame =
        name: r:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            relPath: seed:
            let
              instanceDir = "${dirs.hmConfig}/PrismLauncher/instances/${name}";
            in
            ''nix_minecraft_reseed_config "${seed}" "${instanceDir}/.minecraft/config/${relPath}" "${instanceDir}/.nix-seed-state/config/${relPath}.sha256"''
          ) r.instance.mutableConfigFiles
        );
    in
    ''
      ${reseedFn}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList perGame resolved)}
    ''
  );

  home.activation.minecraftOptionsTxt = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let
      patchFn = ''
        nix_minecraft_patch_line() {
          local file="$1" pattern="$2" newline="$3"
          mkdir -p "$(dirname "$file")"
          if [ ! -e "$file" ]; then
            printf '%s\n' "$newline" > "$file"
            return 0
          fi
          local matches
          matches="$(grep -c -E "$pattern" "$file" || true)"
          if [ "$matches" -eq 0 ]; then
            printf '%s\n' "$newline" >> "$file"
          elif [ "$matches" -eq 1 ]; then
            local tmp
            tmp="$(mktemp)"
            NIX_MC_NEWLINE="$newline" awk -v pat="$pattern" '
              $0 ~ pat { print ENVIRON["NIX_MC_NEWLINE"]; next }
              { print }
            ' "$file" > "$tmp"
            mv "$tmp" "$file"
          else
            echo "minecraft: $file has $matches lines matching /$pattern/ -- expected 0 or 1, refusing to guess which to patch. Resolve by hand, then re-run switch." >&2
            return 1
          fi
        }
      '';
      perGame =
        name: r:
        lib.optionalString (r.resourcePackOrder != null) ''
          nix_minecraft_patch_line \
            "${dirs.hmConfig}/PrismLauncher/instances/${name}/.minecraft/options.txt" \
            '^resourcePacks:' \
            'resourcePacks:${builtins.toJSON r.resourcePackOrder}' || exit 1
        '';
    in
    ''
      ${patchFn}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList perGame resolved)}
    ''
  );
}
