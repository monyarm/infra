{ lib, ... }:
let
  makeTransparentFile = windowClass: transparency: {
    text = ''
      (if (contains (window_class) "${windowClass}")
          (begin
              (spawn_async (str "transset-df -i " (window_xid) ${toString transparency}))
          )
      )
    '';
  };

  makeTransparentFile' = windowClass: makeTransparentFile windowClass 0.85;

  mkJetbrainsTransparentDs =
    names:
    lib.foldl' (
      acc: name:
      acc
      // {
        ".devilspie/jetbrains-${name}_transparent.ds" = makeTransparentFile "jetbrains-${name}" 0.95;
      }
    ) { } names;
in
{
  home.file = {
    ".devilspie/gedit_transparent.ds" = makeTransparentFile' "Org.gnome.gedit";
    ".devilspie/thunar_transparent.ds" = makeTransparentFile' "Thunar";
    ".devilspie/vscode_transparent.ds" = makeTransparentFile' "Code";
  }
  // (mkJetbrainsTransparentDs [
    # keep-sorted start
    "android-studio"
    "appcode"
    "clion"
    "datagrip"
    "dataspell"
    "fleet"
    "goland"
    "idea"
    "phpstorm"
    "pycharm"
    "rider"
    "rubymine"
    "rustrover"
    "webstorm"
    # keep-sorted end
  ]);
}
