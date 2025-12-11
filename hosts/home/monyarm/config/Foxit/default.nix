{
  mkOutOfStoreSymlink,
  dirs,
  ...
}:

{
  xdg.configFile."Foxit Software".source =
    mkOutOfStoreSymlink "${dirs.hmConfig}/Foxit/.config/Foxit Software";
}
