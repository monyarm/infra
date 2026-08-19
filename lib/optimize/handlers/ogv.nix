{ ffmpegStripMetadata, ... }:
# Same Ogg container as ogg.nix, just carrying a Theora video stream
# alongside Vorbis audio -- -c copy remuxes both streams untouched.
ffmpegStripMetadata "ogv"
