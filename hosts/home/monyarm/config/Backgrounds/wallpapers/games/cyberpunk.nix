{
  pkgs,
  toWebp,
  ...
}:
{
  blackwall =
    pkgs.fetchurl {
      url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1091500/c5c1dee0e055b85871883c5fc19a098f53e9778c.webm";
      sha256 = "sha256-FkjhJ5A/WawKokorv7zpT1k01rEd+zRSDtmTmU80j74=";
    }
    |> toWebp;
  consumerism =
    pkgs.fetchurl {
      url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1091500/994eb96bd85c1204e49f38da6e8e90180bdb93c4.webm";
      sha256 = "sha256-NxVA72+FWCsAAESgUT8OwrPjyR1ia9e5vDL4BNMoSV4=";
    }
    |> toWebp;
  cyberpsychosis =
    pkgs.fetchurl {
      url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1091500/4dcf2fa33efef71e8705d2a061af1cf7156574a4.webm";
      sha256 = "sha256-WDLMqRrZDfPlLNBcFiI6jeGoYDil3R9KGthdbbOvoB8=";
    }
    |> toWebp;
  rogueAI =
    pkgs.fetchurl {
      url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1091500/75b1a9153e13599d66d16853be815a6f1fffaeeb.webm";
      sha256 = "sha256-tUXYogINSxnq35djqoD9yhR6CUs+UEmZdIcT/iNV9+k=";
    }
    |> toWebp;
}
