{ fetchSteamCards, ... }:
{
  warhammer40kGladius = fetchSteamCards {
    appId = 489630;
    hash = "sha256-sofSPD/1YOhMy9MctXNYvRdXevShhUlQtnPkW+7L6PM=";
  };
  rogueTraderCRPG = fetchSteamCards {
    appId = 2186680;
    hash = "sha256-FntzZUbQ7YsPQHtiaR8gDiRMPsOFYmOn9k70XoJwISI=";
  };
}
