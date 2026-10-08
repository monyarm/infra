# Per-FILE out-of-store symlinks. Linking the whole GIMP/<version>/ directory
# (the old approach) put the repo at the end of the chain, so everything GIMP
# wrote on exit -- sessionrc, pluginrc, tool-options/, even .goutputstream-*
# temp files -- landed in git.
{
  dirs,
  pkgs,
  mkOutOfStoreSymlink,
  ...
}:
let
  src = "${dirs.hmConfig}/GIMP";
  gimprc = mkOutOfStoreSymlink "${src}/gimprc";
  plug = name: mkOutOfStoreSymlink "${src}/plug-ins/${name}";
in
{
  # The other non-broken gimp3 plug-ins are gimp-with-plugins' default set, but
  # resynthesizer is the one worth having: content-aware fill for areas too big
  # for the clone stamp. The rest of gimpPlugins is 2.10-only (nixpkgs gates it
  # on apiVersion != "2.0").
  home.packages = [
    (pkgs.gimp3-with-plugins.override { plugins = with pkgs.gimp3Plugins; [ resynthesizer ]; })
  ];

  xdg.configFile = {
    # GIMP 3.x reads 3.0/ even at 3.2.x; 2.10/ is for a non-Nix GIMP 2.10.
    "GIMP/2.10/gimprc".source = gimprc;
    "GIMP/3.0/gimprc".source = gimprc;
    # Inert on gimp 3: these are 2.10-era scripts importing the gimp/gimpenums/
    # pygimplib C bindings, which gimp 3 dropped. Its own plug-ins use
    # gi.repository.Gimp. gimp2 has --disable-python (needs EOLed python2).
    "GIMP/3.0/plug-ins/export_layers.py".source = plug "export_layers.py";
    "GIMP/3.0/plug-ins/export_layers".source = plug "export_layers";
  };
}
