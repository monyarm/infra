_:

let
  defaultPassword = "$y$j9T$1zEjlg6jOc7lBZkEYOgN11$/co0iEIS6a.UHhww7GxAxJyrtuUFL9FDYklTPe40z9D";
in

{
  services.libinput.enable = true;

  users.users.root.initialHashedPassword = defaultPassword;
  users.users.monyarm = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialHashedPassword = defaultPassword;
  };
}
