# Doc/OS chrome, no fetcher or engine reads it. Fetcher+engine agnostic --
# gogCruft/scummvmCruft layer their own on top. Plain list, import directly.
[
  "*.pdf" # manuals
  "*.plist" # macOS Info.plist
  "*.doc"
  "*.rtf"
  "*.md" # readmes (not md2/md3 -- Quake models)
  "*.DS_Store" # Finder junk
  "*.bat" # Windows batch scripts
  "Launch_*.lnk" # Not plain LNK, as some dos-era games use that as an extension
  "__redist"
  "webcache.zip"
  "app/webcache.zip"
  "goggame-*.info" # Galaxy metadata, not game data
  "goggame-*.hashdb"
  "goggame-*.ico"
  "goggame-*.png" # Galaxy icon renders (16x16x32 etc.), not game art
  "goggame-*.script" # Galaxy (un)install script
  "goggame-galaxyFileList.ini" # Galaxy file manifest
  "goglog.ini"
  ".DepotDownloader"
  "scummvm" # bundled scummvm, NOT "ScummVM" which also contains lucasarts games in some releases
  "DOSBOX/!dosbox*.conf" # bundled dosbox
  "VERSION"
  "READ*ME*"
  "MANUAL.txt"
  "savegame.___"
  "winsetup.exe"
  "winsetup.ini"
  "setup.exe"
  "setup.ini"
  "install.exe"
  "INSTALL.EXE"
  "*.conf.bak"
  "wallpapers"
  "Wallpapers"
]
