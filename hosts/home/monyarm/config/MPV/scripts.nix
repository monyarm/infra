{
  pkgs,
  uosc,
  ulyssescaballes-mpv-config,
  linkMPV,
  sources,
  fetchGitTree,
  getFile,
  ...
}:
let

  fetchLua = name: fetchGitTree sources.mpv."${name}" |> getFile "${name}.lua";

  mpvInteractiveVideo = fetchLua "interactive-video";

  guessMediaTitle =
    fetchGitTree sources.mpv.zenwarr-config |> getFile "scripts/guess-media-title.lua";

  mpvCoverArt = fetchLua "coverart";

  mpvLRC = pkgs.stdenv.mkDerivation rec {
    pname = "mpv-lrc";
    version = "unstable-${sources.mpv.lrc.rev}";
    src = fetchGitTree sources.mpv.lrc;
    installPhase = ''
      mkdir -p $out
      cp $src/lrc.lua $out/main.lua
      cp $src/lrc.sh $src/lrc.vim $out/ # Used to also have chinese-to-kanji.txt
    '';
  };

  mpvScrollList = fetchLua "scroll-list";

  mpvDvdBrowser = fetchLua "dvd-browser";

  mpvSegmentLinking = fetchLua "segment-linking";

  mpvSponsorblockMinimal = fetchLua "sponsorblock_minimal";

  mpv360 = fetchGitTree sources.mpv.mpv360 |> getFile "scripts/mpv360.lua";

  galleryDlHook = fetchGitTree sources.mpv.jgreco-scripts |> getFile "gallery-dl_hook.lua";

  webtorrentMpvHook = pkgs.webtorrent-js;
  inherit (pkgs) mpris;

  celebi = fetchLua "celebi";

  evafast = fetchLua "evafast";

  memo = fetchLua "memo";

  thumbfast = fetchLua "thumbfast";

  trackselect = fetchLua "trackselect";

  auto-save-state =
    fetchGitTree sources.mpv.AN3223-dotfiles |> getFile ".config/mpv/scripts/auto-save-state.lua";

  quality-menu = fetchLua "quality-menu";

  linkMPVScripts = linkMPV "scripts";
  linkMPVScriptModules = linkMPV "script-modules";
in
{
  xdg.configFile =
    (linkMPVScripts [
      # keep-sorted start
      "${ulyssescaballes-mpv-config}/scripts/file-name-sub-paths.lua"
      auto-save-state
      celebi
      evafast
      galleryDlHook
      guessMediaTitle
      memo
      mpris
      mpv360
      mpvCoverArt
      mpvDvdBrowser
      mpvInteractiveVideo
      #metadataOSD
      mpvLRC
      mpvSegmentLinking
      mpvSponsorblockMinimal
      quality-menu
      thumbfast
      trackselect
      uosc
      webtorrentMpvHook
      # mpvremote # looks for file in wrong place
      # { "mpvremote/remote.db" = "${dirs.config}/MPV/scripts/mpvremote/remote.db"; } # Now handled by linkMpvScripts
      # keep-sorted end
    ])
    // (linkMPVScriptModules [
      # keep-sorted start
      mpvScrollList
      # keep-sorted end
    ]);

}
