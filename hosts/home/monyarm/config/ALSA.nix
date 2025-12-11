{ format, ... }:
{
  home.file = {
    ".asoundrc" = {
      text = format.toRCFile {
        defaults = {
          bluealsa = {
            service = "org.bluealsa";
            device = "A4:77:58:76:71:A5";
            profile = "a2dp";
            delay = 10000;
          };
        };
      };
    };

  };
}
