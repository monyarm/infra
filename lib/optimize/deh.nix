{ removeLineComments, ... }:
# DeHackEd/BEX patch files: whole-line "#" comments are safe to strip (the
# format's own convention -- see e.g. real-world aoddoom2.deh's own header:
# "Use the pound sign ('#') to start comment lines"), but "#" also shows up
# mid-line as real data (e.g. "ID # = 64"), so only leading-# lines count.
# "Text <fromLen> <toLen>" blocks are raw, length-prefixed replacement text
# that can itself contain blank lines or lines starting with "#" (verified
# against a real file); protectAfter keeps that exact byte range untouched.
# Blank lines are left alone: no BEX equivalent of a Text-block-safe
# removeBlankLines call here, since it isn't worth a second pass over the
# same protected-range bookkeeping for what's a much smaller win.
src:
src
|> removeLineComments {
  prefixes = [ "#" ];
  protectAfter = "^Text[ \t]+([0-9]+)[ \t]+([0-9]+)[ \t]*$";
}
