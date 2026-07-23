{ lib, fetchWithReferrer, ... }:
{
  fetchGelbooru =
    args:
    fetchWithReferrer "https://gelbooru.com/" (
      args
      // {
        url = builtins.replaceStrings [
          "https://img.gelbooru.com/"
          "https://img1.gelbooru.com/"
          "https://img2.gelbooru.com/"
          "https://img3.gelbooru.com/"
        ] (lib.lists.replicate 4 "https://img4.gelbooru.com/") args.url;
      }
    );
}
