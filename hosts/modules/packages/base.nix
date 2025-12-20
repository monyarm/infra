{
  pkgs,
  ...
}:
let
  basePackages =
    with pkgs;
    (builtins.concatLists (
      builtins.attrValues {
        cli = [
          # keep-sorted start
          bat
          curl
          diskus
          eza
          git
          gnupg
          htop
          jq
          ripgrep
          tree
          wget
          # keep-sorted end
        ];
        dev = [
          direnv
          yarn
        ];
      }
    ));
in
{
  environment.systemPackages = basePackages;
}
