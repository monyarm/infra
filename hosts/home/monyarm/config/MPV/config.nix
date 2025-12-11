{
  meta,
  lib,
  ...
}:

{
  programs.mpv.config = {
    # PROFILE & MODULARITY
    input-default-bindings = true;

    # VIDEO OUTPUT & CONTEXT
    vo = "gpu-next";
    gpu-api = if (meta.deviceType != "android") then "vulkan" else "opengl";
    gpu-context = if (meta.deviceType != "android") then "waylandvk" else "android";

    # HARDWARE DECODING
    hwdec = if (meta.gpu == "nvidia") then "nvdec" else "auto";
    hwdec-codecs = "all";
    hwdec-extra-frames = 12;

    # HDR & TONE MAPPING
    hdr-peak-percentile = 99.995;
    hdr-compute-peak = true;
    hdr-contrast-recovery = 0.55;
    tone-mapping = "bt.2390";
    tone-mapping-param = 1.2;
    target-colorspace-hint = true;

    # SEEKING
    hr-seek = true;
    hr-seek-framedrop = false;

    # YTDL FORMAT FILTER
    ytdl-format = "bestvideo+bestaudio[format_id!*=-drc]/best";

    # SHADER STACK (Enhanced)
    glsl-shaders = [
      "~~/shaders/FSRCNNX_x2_16-0-4-1.glsl"
      "~~/shaders/SSimSuperRes.glsl"
      "~~/shaders/adaptive-sharpen.glsl"
    ];

    # SCALING & RESAMPLING
    scale = "ewa_lanczossharp";
    dscale = "lanczos";
    cscale = "spline64";
    scale-antiring = 0.7;
    dscale-antiring = 0.7;
    cscale-antiring = 0.7;
    correct-downscaling = true;
    linear-downscaling = false;
    sigmoid-upscaling = true;

    # INTERPOLATION & SYNC
    interpolation = true;
    video-sync = "display-vdrop";
    tscale = "oversample";
    tscale-blur = 0.6991556596428412;
    tscale-window = "sphinx";
    tscale-clamp = 0.0;

    # DITHERING
    dither-depth = "auto";
    dither = "fruit";
    temporal-dither = true;

    # DEBANDING
    deband = true;
    deband-iterations = 2;
    deband-threshold = 48;
    deband-range = 18;
    deband-grain = 32;

    # AUDIO
    volume = 50;
    volume-max = 130;
    gapless-audio = true;
    audio-pitch-correction = true;
    audio-channels = "auto";
    audio-file-auto = "fuzzy";
    audio-normalize-downmix = false;
    af = "lavfi=[acompressor=threshold=-18dB:ratio=2.5:attack=50:release=200],dynaudnorm";

    # PLAYBACK BEHAVIOR
    keep-open = true;
    keep-open-pause = false;
    idle = true;
    force-seekable = true;
    save-position-on-quit = true;
    watch-later-options = "all";
    directory-mode = "ignore";

    # WINDOW & UI
    osc = false;
    border = false;
    autofit = "70%x70%";
    geometry = "50%:50%";
    snap-window = true;
    cursor-autohide = 280;

    # SUBTITLES
    sub-font = lib.mkForce "Segoe UI Light";
    sub-font-size = 40;
    sub-color = "#ffffff";
    sub-border-size = 1.2;
    sub-outline-color = "#dddddd";
    sub-shadow-color = "#000000";
    sub-shadow-offset = 0.7;
    sub-blur = 0.6;
    sub-back-color = "#00000000";
    sub-auto = "all";
    sub-ass-override = false;
    sub-fix-timing = true;
    blend-subtitles = true;
    demuxer-mkv-subtitle-preroll = true;
    sub-file-paths = "sub,subs,subtitles";
    slang = "en,eng,English";
    alang = "en,eng,English";

    # OSD
    osd-align-x = "center";
    osd-font-size = 28;

    # CACHE & PATHS
    demuxer-max-bytes = "200MiB";
    demuxer-max-back-bytes = "100MiB";
    cache-secs = 60;
    gpu-shader-cache-dir = "~~/cache/shader_cache";
    watch-later-dir = "~~/cache/watch_later";
    screenshot-dir = "~~/screenshots";

    # LOGGING
    msg-level = "cplayer=error";
  };
}
