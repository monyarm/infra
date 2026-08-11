{ ffmpegStripMetadata, ... }:
# ASF header metadata strip, verified lossless (decoded PCM identical
# before/after on a real ffmpeg-generated WMA, same approach as wav.nix's
# stripMetadata).
ffmpegStripMetadata "wma"
