{ ffmpegStripMetadata, ... }:
# ID3 metadata strip, verified lossless (decoded PCM identical before/after
# on a real tagged file, same approach as wav.nix's stripMetadata).
ffmpegStripMetadata "mp3"
