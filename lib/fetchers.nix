{ pkgs, ... }:
{
  fetchProtonGE =
    version: hash:
    let
      name = "GE-Proton${version}";
    in
    pkgs.fetchzip {
      inherit name hash;
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${name}/${name}.tar.gz";
    };
}
