{ fetchSteamCards, ... }:
{
  mightMagicFatesTCG = fetchSteamCards {
    appId = 3918850;
    hash = "sha256-wyMQ9Bbe01FTPYsg5xEWgoCt9KEXO8t6AhC6FcH/YTA=";
  };
  heroesOfMightMagicOldenEra = fetchSteamCards {
    appId = 3105440;
    hash = "sha256-XO5kMaRz0sO835kZ/CmVAXPuc5eKFHrL6vKoAhQArdE=";
  };
}
