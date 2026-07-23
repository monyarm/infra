# config/MPV/shaders.nix
{
  lib,
  pkgs,
  sources,
  getFile,
  fetchGitTree,
  ...
}:

let
  urlShaders = [
    {
      name = "FSRCNNX_x2_16-0-4-1.glsl";
      url = "https://github.com/igv/FSRCNN-TensorFlow/releases/download/1.1/FSRCNNX_x2_16-0-4-1.glsl";
      sha256 = "sha256-1aJKJx5dmj9/egU7FQxGCkTCWzz393CFfVfMOi4cmWU=";
    }
    {
      name = "FSRCNNX_x2_16-0-4-1_anime_enhance.glsl";
      url = "https://github.com/HelpSeeker/FSRCNN-TensorFlow/releases/download/1.1_distort/FSRCNNX_x2_16-0-4-1_anime_enhance.glsl";
      sha256 = "sha256-ss+FXE4AuqYJpqVpGtCjbcH8GjScqd55rEec6pyxygU=";
    }
    {
      name = "SSimSuperRes.glsl";
      url = "https://gist.githubusercontent.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b/raw/15d93440d0a24fc4b8770070be6a9fa2af6f200b/SSimSuperRes.glsl";
      sha256 = "sha256-qLJxFYQMYARSUEEbN14BiAACFyWK13butRckyXgVRg8=";
    }
    {
      name = "adaptive-sharpen.glsl";
      url = "https://gist.githubusercontent.com/igv/8a77e4eb8276753b54bb94c1c50c317e/raw/adaptive-sharpen.glsl";
      sha256 = "sha256-gn+z1mKsmpG0B16RF/5uHbwcBthZWbpxnNuVTft/uOQ=";
    }
  ];
in

{

  xdg.configFile = {
    "mpv/shaders" = {
      source = pkgs.fetchzip {
        url = "https://github.com/bloc97/Anime4K/releases/download/v4.0.1/Anime4K_v4.0.zip";
        sha256 = "sha256-9B6U+KEVlhUIIOrDauIN3aVUjZ/gQHjFArS4uf/BpaM=";
        stripRoot = false;
      };
      recursive = true;
    };

    "mpv/shaders/mpv360.glsl".source =
      fetchGitTree sources.mpv.mpv360 |> getFile "shaders/mpv360.glsl";

    "mpv/shaders/ArtCNN_C4F16.glsl".source =
      fetchGitTree sources.mpv.ArtCNN |> getFile "GLSL/ArtCNN_C4F16.glsl";

    "mpv/shaders/ArtCNN_C4F32_DS.glsl".source =
      fetchGitTree sources.mpv.ArtCNN |> getFile "GLSL/ArtCNN_C4F32_DS.glsl";
  }
  // (lib.listToAttrs (
    map (s: {
      name = "mpv/shaders/${s.name}";
      value.source = pkgs.fetchurl { inherit (s) url sha256; };
    }) urlShaders
  ));

}
