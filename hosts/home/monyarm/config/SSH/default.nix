{
  lib,
  ...
}:

with lib;

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        setEnv = ''TERM="xterm-256color"'';
      };
    };
  };
}
