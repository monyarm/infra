# config/MPV/profiles.nix
_:

{
  programs.mpv.profiles = rec {
    "protocol.file" = {
      profile-desc = "Default behavior for local files";
    };

    protocol-network = {
      profile-desc = "Optimized for network streaming";
      cache = true;
      demuxer-max-bytes = "400MiB";
      demuxer-readahead-secs = 600;
    };

    "protocol.http" = {
      profile = "protocol-network";
    };

    "protocol.https" = {
      profile = "protocol-network";
    };

    "protocol.ytdl" = {
      profile = "protocol-network";
      force-window = "immediate";
    };

    "extension.gif" = {
      profile-desc = "Loop playback for GIF files";
      "loop-file" = "yes";
    };

    "extension.png" = {
      profile-desc = "Default behavior for PNG images";
    };

    "extension.jpg" = {
      profile-desc = "Default behavior for JPEG images";
    };

    "extension.jpeg" = {
      profile-desc = "Default behavior for JPEG images";
    };

    "Anime4K-A" = {
      profile-desc = "Anime4K: Mode A (HQ)";
      glsl-shaders = [
        "~~/shaders/Anime4K_Clamp_Highlights.glsl"
        "~~/shaders/Anime4K_Restore_CNN_VL.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
    "Anime4K-B" = {
      profile-desc = "Anime4K: Mode B (HQ)";
      glsl-shaders = [
        "~~/shaders/Anime4K_Clamp_Highlights.glsl"
        "~~/shaders/Anime4K_Restore_CNN_Soft_VL.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
    "Anime4K-C" = {
      profile-desc = "Anime4K: Mode C (HQ)";
      glsl-shaders = [
        "~~/shaders/Anime4K_Clamp_Highlights.glsl"
        "~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
    "Anime4K-A+A" = {
      profile-desc = "Anime4K: Mode A+A (HQ)";
      glsl-shaders = [
        "~~/shaders/Anime4K_Clamp_Highlights.glsl"
        "~~/shaders/Anime4K_Restore_CNN_VL.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl"
        "~~/shaders/Anime4K_Restore_CNN_M.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
    "Anime4K-B+B" = {
      profile-desc = "Anime4K: Mode B+B (HQ)";
      glsl-shaders = [
        "~~/shaders/Anime4K_Clamp_Highlights.glsl"
        "~~/shaders/Anime4K_Restore_CNN_Soft_VL.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl"
        "~~/shaders/Anime4K_Restore_CNN_Soft_M.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
    "Anime4K-C+A" = {
      profile-desc = "Anime4K: Mode C+A (HQ)";
      glsl-shaders = [
        "~~/shaders/Anime4K_Clamp_Highlights.glsl"
        "~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl"
        "~~/shaders/Anime4K_Restore_CNN_M.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
    "ArtCNN" = {
      profile-desc = "ArtCNN C4F16 + Adaptive Sharpen";
      glsl-shaders = [
        "~~/shaders/ArtCNN_C4F16.glsl"
        "~~/shaders/adaptive-sharpen.glsl"
      ];
    };
    "no-shaders" = {
      profile-desc = "GLSL shaders cleared";
      glsl-shaders = [ ];
    };
  };
}
