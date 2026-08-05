{ ffmpegStripMetadata, ... }:
# Vorbis-comment metadata strip, verified lossless (decoded PCM identical
# before/after on a real tagged file, same approach as wav.nix's
# stripMetadata).
ffmpegStripMetadata "ogg"
