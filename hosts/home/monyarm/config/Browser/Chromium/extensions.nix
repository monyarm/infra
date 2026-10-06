# Web-store extensions, installed via HM's External Extensions mechanism.
#
# No CRX vendoring needed: HM's default updateUrl is already
# https://clients2.google.com/service/update2/crx, so an id-only entry keeps
# auto-update working.
#
# Deliberately NOT listed: mhjfbmdgcfjbbpaeojofohoefgiehjai (Chromium PDF
# Viewer) and nkeimhogjdpnpccoofpliimaahmaaome (Google Hangouts). Both are
# `location: 5` built-in component extensions -- not installable, and the
# ExtensionInstallForcelist / External Extensions mechanisms cannot add them.
_: {
  programs.chromium.extensions = [
    # OpenCode Browser Annotation 0.6.2
    { id = "baleoognciaapjfjbhnibondmlodnddp"; }
    # uBlock Origin Lite 2026.930.1227
    { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; }
  ];
}
