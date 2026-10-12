# Example PSP memory card.
#
# Demonstrates the resource model: games and homebrew each declare exactly one
# category, and Categories Lite turns that into the on-card directory layout.
{
  psp.categoriesLite = {
    enable = true;
    prefix = true;
    sort = false;
  };

  psp.games = {
    lumines = {
      type = "psp-iso";
      source = ./art/lumines.iso;
      category = "Puzzle";
      metadata.title = "Lumines";
    };

    jeanneDA = {
      type = "psp-iso";
      source = ./art/jeanne-darc.iso;
      category = "Strategy";
      metadata.title = "Jeanne d'Arc";
    };
  };

  psp.homebrew = {
    pspfiler = {
      package = ./art/pspfiler;
      category = "Homebrew";
      metadata = {
        title = "PSP Filer";
        icon = ./art/icon.png;
      };
    };

    # Built from source by the PSP toolchain; no prebuilt package needed.
    hello = {
      src = ./hellosrc;
      category = "Homebrew";
      metadata.title = "Hello PSP";
    };
  };

  # Escape hatch for anything the resource model does not cover.
  psp.files."SEPLUGINS/README.TXT".text = ''
    Managed by nix. Edits on the card are reverted on the next apply.
  '';

  # Plugins are enabled by name; the registry supplies the download, the
  # destination, and the runlevel.
  psp.plugins = {
    categories-lite.enable = true;
    missyhud.enable = true;
    cxmb.enable = true;
    cwcheat.enable = true;
  };

  psp.cfw.ark5 = {
    enable = true;
    settings = {
      usbcharge = true;
      cpuclock = "333";
      noled = false;
    };
  };
}
