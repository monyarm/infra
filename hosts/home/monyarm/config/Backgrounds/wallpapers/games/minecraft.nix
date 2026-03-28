{ pkgs, ... }:
let
  fetchMinecraftBase =
    {
      name,
      paperName ? name,
      sha256,
      prefix,
      filePrefix ? prefix,
    }:
    "${
      pkgs.fetchzip {
        url = "https://www.minecraft.net/content/dam/minecraftnet/games/minecraft/software/${prefix}${name}.zip";
        inherit sha256;
        stripRoot = false;
        curlOptsList = [
          "-A"
          "Mozilla"
        ];
      }
    }/${filePrefix}${paperName}_1920x1080.png";

  fetchMinecraft =
    args:
    fetchMinecraftBase (
      args
      // {
        prefix = "Minecraft_";
        filePrefix = "Minecraft_";
      }
    );
  fetchMinecraftWallpapers =
    args:
    fetchMinecraftBase (
      args
      // {
        prefix = "wallpapers_";
        filePrefix = "wallpaper_";
      }
    );
  fetchMinecraftWallpaper =
    args:
    fetchMinecraftBase (
      args
      // {
        prefix = "wallpaper_";
      }
    );
in
{
  bedrockEdition = fetchMinecraftWallpapers {
    name = "minecraft_bedrock_edition";
    sha256 = "sha256-wYrQR+KC2XnumGSW/polTEjbNae0VF5dR3SiEwr9Ilc=";
  };
  javaEdition = fetchMinecraftWallpapers {
    name = "minecraft_java_edition";
    sha256 = "sha256-IsZ186C39RRyJHqtLA69LLY4DmyKQzyaV3zq6I4GB6M=";
  };
  pcBundle = fetchMinecraftWallpapers {
    name = "minecraft_pc_bundle";
    sha256 = "sha256-8wFeB59QUiBNLMkEwdAO4FElc88iTvjqd/WNMfvfryY=";
  };
  mountsOfMayhemDrop = fetchMinecraftWallpapers {
    name = "mounts_of_mayhem_drop";
    sha256 = "sha256-2yFqLPZdtagF+S+S0wgbo++GFmBcSXd9DVYtRp0fstk=";
  };
  theCopperAgeDrop1 = fetchMinecraftWallpapers {
    name = "the_copper_age_drop-1";
    sha256 = "sha256-ASlD8k8Wcr2NlWgBRj6RW/riHx3dvhubRuvEC9rB1Zk=";
  };
  chaseTheSkiesUpdate = fetchMinecraftWallpapers {
    name = "chase_the_skies_update";
    sha256 = "sha256-czylpvATUGoPumE3bPjeYsz7TFw4PPD6XIosviRT01M=";
  };
  springToLifeUpdate = fetchMinecraftWallpapers {
    name = "spring_to_life_update";
    sha256 = "sha256-ByJESmNgUvjOCiVPbGh1IWVltl8gadBCS+ymFH3s7OM=";
  };
  theGardenAwakensUpdate = fetchMinecraftWallpapers {
    name = "the_garden_awakens_update";
    sha256 = "sha256-QUA/CHf+NWBoFAbUhKN7FDus6uFKHO/39GVx6IBGc8c=";
  };
  bundlesOfBravery = fetchMinecraftWallpapers {
    name = "bundles_of_bravery";
    sha256 = "sha256-XHH1JJTtW4dbN31ou+ZJeRIxnaX/+BNQKWtgdluYKZ8=";
  };
  trickyTrialsUpdate2 = fetchMinecraftWallpapers {
    name = "tricky_trials_update2";
    sha256 = "sha256-eZe4ZYRMLozMNPrB+Zuu3U8Z0++P8RZEP5iantoB3R0=";
  };
  trailsAndTales = fetchMinecraft {
    name = "Trails_and_Tales_.Net";
    paperName = "Trails&Tales_.Net";
    sha256 = "sha256-Xe32GmTgOLJkpl1PRKixewUMs1iulBo68SrrxnVe6Bk=";
  };
  wildUpdate = fetchMinecraftWallpaper {
    name = "minecraft_wild_update";
    sha256 = "sha256-7HCg3wSgGBlbSCI2K7ZtvsQ1Vnia+aP/LEO+vaXCI0A=";
  };
  cavesCliffs1 = fetchMinecraftWallpapers {
    name = "minecraft_caves_cliffs(part1)";
    sha256 = "sha256-ebe48TohAnZ5JYpNk64B6A3lLT9nXyhobyT/wGTXmho=";
  };
  cavesCliffs2 = fetchMinecraftWallpapers {
    name = "minecraft_caves_cliffs(part2)";
    sha256 = "sha256-0qj4fdDyF/zPj+EXqkYjJRL2mP3QXh9f/ycKr5yZzRs=";
  };
  netherUpdate = fetchMinecraftWallpapers {
    name = "minecraft_nether_update";
    sha256 = "sha256-eGVx7JR+RUyFF7L3CvmL53uSiwkT09pv5vYaQZSM6c8=";
  };
  buzzyBees = fetchMinecraftWallpapers {
    name = "minecraft_buzzybees";
    sha256 = "sha256-ThcXYPeIzODNSMkbuKxgicGllhis3w9FjJYysLQgY3c=";
  };
  villagePillage = fetchMinecraftWallpapers {
    name = "minecraft_village_pillage";
    sha256 = "sha256-aCvUhL78Bv607vnNg3dorVz9NkIW/ZTz2sM6CZQc0kQ=";
  };
  updateAquatic = fetchMinecraftWallpapers {
    name = "minecraft_update_aquatic";
    sha256 = "sha256-macxxTyCOOyTQukZSB1ysHes40oWdarMmXjdi6sLy4Q=";
  };
  catsPandas = fetchMinecraftWallpaper {
    name = "minecraft_cats_pandas";
    sha256 = "sha256-xApX1ypBlFxzqYqR0vwEmXANG20HNxLu5xVQAcRH+P0=";
  };
  worldColor = fetchMinecraftWallpapers {
    name = "minecraft_world_color";
    sha256 = "sha256-/+AHn79LZIMhDml4bHmEqU4ZdS5DK8isDcgVEiC7nGE=";
  };
  oceanMonument = fetchMinecraftWallpapers {
    name = "minecraft_ocean_monument_";
    sha256 = "sha256-6h5NkHP6puS2o86j9IVWFvyI8e9TDAvj1hk+16VbFUA=";
  };
  island = fetchMinecraftWallpapers {
    name = "minecraft_island";
    sha256 = "sha256-qDDsmmLYfjdxMbhEEtR3hAH8nkP0vxAja/V5wIN8C50=";
  };
  mineshaft = fetchMinecraftWallpapers {
    name = "minecraft_mineshaft";
    sha256 = "sha256-IVkWXzbizH0iKHjwfshkKfwupTWDmbFyMFQoRLQ2ZIg=";
  };
  campEnderwood = fetchMinecraftWallpapers {
    name = "marketplace_camp_enderwood";
    sha256 = "sha256-5KqXL845GfVhmQTNU5uDSQ/nMQ89YerIJ1LfiUhFD9A=";
  };
  spongebob = fetchMinecraftWallpapers {
    name = "marketplace_spongebob";
    sha256 = "sha256-RzFphiH8O6MKK98/NOHjiu8KI8nPXjjsQDzYQQaloLs=";
  };
  sonic = fetchMinecraftWallpapers {
    name = "marketplace_sonic";
    sha256 = "sha256-wHX7Ak+fa1q25kX9kzWIIg24JR+2vQFmD6NhVJ6S83U=";
  };
  starWars = fetchMinecraftWallpapers {
    name = "marketplace_star_wars";
    sha256 = "sha256-SJrs+lTqCP+DQ1+1wJ4ee8fW4q+JwEpQ0m24qVGU7ZI=";
  };
  waltDisney = fetchMinecraftWallpapers {
    name = "marketplace_walt_disney";
    sha256 = "sha256-IKEulTxeiVikBPCWLkogXT09XccFtIQq1sBqRfq4o5A=";
  };
  nycCelebration = fetchMinecraftWallpapers {
    name = "marketplace_nyc_celebration";
    sha256 = "sha256-pa5hJF0rRdIvhL/+BjpngHVkPgflPGQ5lZ1eJ8zQ6DY=";
  };
  megaman = fetchMinecraftWallpapers {
    name = "marketplace_megaman";
    sha256 = "sha256-YxmsoEYzyGHGzPhrSbPOtAUuI6YzFdy6so+Y6E3vv9E=";
  };
  sonicTextures = fetchMinecraftBase {
    name = "SonicTextures";
    paperName = "SonicTextures_.net";
    prefix = "";
    sha256 = "sha256-j4SoPKNlC9QhYk1wgT//Vo+ENHEPR/eZrPVL5nh67F0=";
  };
  dnd = fetchMinecraft {
    name = "Dungeons_and_Dragons.net";
    paperName = "Dungeons and Dragons_.net";
    sha256 = "sha256-ofwAwT83D2BtPsuR9fWn5gK4cKF/DGQcuEVXhc6VjVQ=";
  };

}
