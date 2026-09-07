{
  config = {
    # Modrinth-backed, used as-is (modpackVersion defaults to "latest").
    games.minecraft.games.society-sunlit-valley = {
      modpack = "society-sunlit-valley";
    };

    # Custom modpack proving the text-based/"latest" resolution path
    # against an explicitly-registered mod. Uses Forge (rather than the
    # Fabric loader in the original design) because PrismLauncher meta's
    # fabric-loader version files use a differently-shaped libraries[]
    # entry (repo-base "url" + no published hash, vs. everything else's
    # "downloads":{"artifact":{...}}) that isn't supported yet -- follow-up
    # item, not needed to prove the selector mechanism itself.
    games.minecraft.modpacks.poc-custom = {
      minecraftVersion = "1.20.1";
      loader = "forge";
      loaderVersion = "47.4.0";
      mods = {
        jei = "latest";
      };
    };
    games.minecraft.games.poc-custom = {
      modpack = "poc-custom";
    };
  };
}
