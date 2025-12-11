{ lib, ... }:

{
  xdg.configFile."dosbox/dosbox-staging.conf".text = lib.generators.toINI { } {
    # This is the configuration file for dosbox-staging (0.78.1).
    # Lines starting with a '#' character are comments.

    sdl = {
      #         fullscreen: Start directly in fullscreen.
      #                     Run INTRO and see Special Keys for window control hotkeys.
      fullscreen = false;
      #            display: Number of display to use; values depend on OS and user settings.
      display = 0;
      #     fullresolution: What resolution to use for fullscreen: 'original', 'desktop'
      #                     or a fixed size (e.g. 1024x768).
      fullresolution = "desktop";
      #   windowresolution: Set window size when running in windowed mode:
      #                       default:   Select the best option based on your
      #                                  environment and other settings.
      #                       small, medium, or large (or s, m, l):
      #                                  Size the window relative to the desktop.
      #                       <custom>:  Scale the window to the given dimensions in
      #                                  WxH format. For example: 1024x768.
      #                                  Scaling is not performed for output=surface.
      windowresolution = "default";
      #    window_position: Set initial window position when running in windowed mode:
      #                       auto:      Let the window manager decide the position.
      #                       <custom>:  Set window position in X,Y format. For example: 250,100
      #                                  0,0 is the top-left corner of the screen.
      window_position = "auto";
      # window_decorations: Controls whether to display window decorations in windowed mode.
      window_decorations = true;
      #              vsync: Synchronize with display refresh rate if supported. This can
      #                     reduce flickering and tearing, but may also impact performance.
      vsync = false;
      #         vsync_skip: Number of microseconds to allow rendering to block before skipping the next frame. 0 disables this and will always render.
      vsync_skip = 7000;
      #     max_resolution: Optionally restricts the viewport resolution within the window/screen:
      #                       auto:      The viewport fills the window/screen (default).
      #                       <custom>:  Set max viewport resolution in WxH format.
      #                                  For example: 960x720
      max_resolution = "auto";
      #             output: What video system to use for output.
      #                     Possible values: surface, texture, texturenb, texturepp, opengl, openglnb, openglpp.
      output = "opengl";
      #   texture_renderer: Choose a renderer driver when using a texture output mode.
      #                     Use texture_renderer=auto for an automatic choice.
      #                     Possible values: auto, opengl, opengles2, software.
      texture_renderer = "auto";
      #      capture_mouse: Choose a mouse control method:
      #                        onclick:        Capture the mouse when clicking any button in the window.
      #                        onstart:        Capture the mouse immediately on start.
      #                        seamless:       Let the mouse move seamlessly; captures only with middle-click or hotkey.
      #                        nomouse:        Hide the mouse and don't send input to the game.
      #                     Choose how middle-clicks are handled (second parameter):
      #                        middlegame:     Middle-clicks are sent to the game.
      #                        middlerelease:  Middle-click will release the captured mouse, and also capture when seamless.
      #                     Defaults (if not present or incorrect): seamless middlerelease
      #                     Possible values: seamless, onclick, onstart, nomouse.
      capture_mouse = "seamless middlerelease";
      #        sensitivity: Mouse sensitivity. The optional second parameter specifies vertical sensitivity (e.g. 100,-50).
      sensitivity = 100;
      #    raw_mouse_input: Enable this setting to bypass your operating system's mouse
      #                     acceleration and sensitivity settings. This works in
      #                     fullscreen or when the mouse is captured in window mode.
      raw_mouse_input = false;
      #        waitonerror: Wait before closing the console if dosbox has an error.
      waitonerror = true;
      #           priority: Priority levels for dosbox. Second entry behind the comma is for when dosbox is not focused/minimized.
      #                     pause is only valid for the second entry. auto disables priority levels and uses OS defaults
      #                     Possible values: auto, lowest, lower, normal, higher, highest, pause.
      priority = "auto,auto";
      #         mapperfile: File used to load/save the key/event mappings from.
      #                     Resetmapper only works with the default value.
      mapperfile = "mapper-sdl2-0.78.1.map";
      #        screensaver: Use 'allow' or 'block' to override the SDL_VIDEO_ALLOW_SCREENSAVER
      #                     environment variable (which usually blocks the OS screensaver
      #                     while the emulator is running).
      #                     Possible values: auto, allow, block.
      screensaver = "auto";
    };

    dosbox = {
      #          language: Select a language to use: de, en, es, fr, it, pl, and ru
      #                    Notes: This setting will override the 'LANG' environment, if set.
      #                           The 'translations' directory bundled with the executable holds these data
      #                           files. Please keep it along-side the executable to support this feature.
      language = "";
      #           machine: The type of machine DOSBox tries to emulate.
      #                    Possible values: hercules, cga, cga_mono, tandy, pcjr, ega, vgaonly, svga_s3, svga_et3000, svga_et4000, svga_paradise, vesa_nolfb, vesa_oldvbe.
      machine = "svga_s3";
      #          captures: Directory where things like wave, midi, screenshot get captured.
      captures = "capture";
      #           memsize: Amount of memory DOSBox has in megabytes.
      #                    This value is best left at its default to avoid problems with some games,
      #                    though few games might require a higher value.
      #                    There is generally no speed advantage when raising this value.
      memsize = 16;
      #          vmemsize: Video memory in MiB (1-8) or KiB (256 to 8192). 'auto' uses the default per video adapter.
      #                    Possible values: auto, 1, 2, 4, 8, 256, 512, 1024, 2048, 8192.
      vmemsize = "auto";
      #        vesa_modes: Controls the selection of VESA 1.2 and 2.0 modes offered:
      #                      compatible   A tailored selection that maximizes game compatibility.
      #                                   This is recommended along with 4 or 8 MB of video memory.
      #                      all          Offers all modes for a given video memory size, however
      #                                   some games may not use them properly (flickering) or may need
      #                                   more system memory (mem = ) to use them.
      #                    Possible values: compatible, all.
      vesa_modes = "compatible";
      #        speed_mods: Permit changes known to improve performance. Currently no games are known
      #                    to be affected by this. Please file a bug with the project if you find a
      #                    game that fails when this is set to true so we will list them here.
      speed_mods = true;
      #  autoexec_section: How autoexec sections are handled from multiple config files.
      #                    join      : combines them into one big section (legacy behavior).
      #                    overwrite : use the last one encountered, like other conf settings.
      #                    Possible values: join, overwrite.
      autoexec_section = "join";
      # startup_verbosity: Controls verbosity prior to displaying the program:
      #                    Verbosity   | Splash | Welcome | Early stdout
      #                    high        |  yes   |   yes   |    yes
      #                    medium      |  no    |   yes   |    yes
      #                    low         |  no    |   no   |    yes
      #                    quiet       |  no    |   no   |    no
      #                    splash_only |  yes   |   no   |    no
      #                    auto        | 'low' if exec or dir is passed, otherwise 'high'
      #                    Possible values: auto, high, medium, low, splash_only, quiet.
      startup_verbosity = "auto";
    };

    render = {
      #          frameskip: How many frames DOSBox skips before drawing one.
      frameskip = 0;
      #             aspect: Scales the vertical resolution to produce a 4:3 display aspect
      #                     ratio, matching that of the original standard-definition monitors
      #                     for which the majority of DOS games were designed. This setting
      #                     only affects video modes that use non-square pixels, such as
      #                     320x200 or 640x400; where as square-pixel modes, such as 640x480
      #                     and 800x600, will be displayed as-is.
      aspect = true;
      # monochrome_palette: Select default palette for monochrome display.
      #                     Works only when emulating hercules or cga_mono.
      #                     You can also cycle through available colours using F11.
      #                     Possible values: white, paperwhite, green, amber.
      monochrome_palette = "white";
      #             scaler: Scaler used to enlarge/enhance low resolution modes.
      #                     If 'forced' is appended, then the scaler will be used even if
      #                     the result might not be desired.
      #                     Note that some scalers may use black borders to fit the image
      #                     within your configured display resolution. If this is
      #                     undesirable, try either a different scaler or enabling
      #                     fullresolution output.
      #                     Possible values: none, normal2x, normal3x, advmame2x, advmame3x, advinterp2x, advinterp3x, hq2x, hq3x, 2xsai, super2xsai, supereagle, tv2x, tv3x, rgb2x, rgb3x, scan2x, scan3x.
      scaler = "none";
      #           glshader: Either 'none' or a GLSL shader name. Works only with
      #                     OpenGL output.  Can be either an absolute path, a file
      #                     in the 'glshaders' subdirectory of the DOSBox
      #                     configuration directory, or one of the built-in shaders:
      #                     advinterp2x, advinterp3x, advmame2x, advmame3x,
      #                     crt-easymode-flat, crt-fakelottes-flat, rgb2x, rgb3x,
      #                     scan2x, scan3x, tv2x, tv3x, sharp (default).
      glshader = "default";
    };

    composite = {
      #   composite: Enable composite mode on start. 'auto' lets the program decide.
      #              Note: Fine-tune the settings below (ie: hue) using the composite hotkeys.
      #                    Then read the new settings from your console and enter them here.
      #              Possible values: auto, on, off.
      composite = "auto";
      #         era: Era of composite technology. When 'auto', PCjr uses new and CGA/Tandy use old.
      #              Possible values: auto, old, new.
      era = "auto";
      #         hue: Appearance of RGB palette. For example, adjust until sky is blue.
      hue = 0;
      #  saturation: Intensity of colors, from washed out to vivid.
      saturation = 100;
      #    contrast: Ratio between the dark and light area.
      contrast = 100;
      #  brightness: Luminosity of the image, from dark to light.
      brightness = 0;
      # convergence: Convergence of subpixel elements, from blurry to sharp (CGA and Tandy-only).
      convergence = 0;
    };

    cpu = {
      #      core: CPU Core used in emulation. auto will switch to dynamic if available and
      #            appropriate.
      #            Possible values: auto, dynamic, normal, simple.
      core = "auto";
      #   cputype: CPU Type used in emulation. auto is the fastest choice.
      #            Possible values: auto, 386, 386_slow, 486_slow, pentium_slow, 386_prefetch.
      cputype = "auto";
      #    cycles: Number of instructions DOSBox tries to emulate each millisecond.
      #            Setting this value too high results in sound dropouts and lags.
      #            Cycles can be set in 3 ways:
      #              'auto'          tries to guess what a game needs.
      #                              It usually works, but can fail for certain games.
      #              'fixed #number' will set a fixed number of cycles. This is what you usually
      #                              need if 'auto' fails (Example: fixed 4000).
      #              'max'           will allocate as much cycles as your computer is able to
      #                              handle.
      #            Possible values: auto, fixed, max.
      cycles = "auto";
      #   cycleup: Number of cycles added or subtracted with speed control hotkeys.
      #            Run INTRO and see Special Keys for list of hotkeys.
      cycleup = 10;
      # cycledown: Setting it lower than 100 will be a percentage.
      cycledown = 20;
    };

    mixer = {
      #   nosound: Enable silent mode, sound is still emulated though.
      nosound = false;
      #      rate: Mixer sample rate, setting any device's rate higher than this will probably lower their sound quality.
      #            Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
      rate = 48000;
      # blocksize: Mixer block size, larger blocks might help sound stuttering but sound will also be more lagged.
      #            Possible values: 1024, 2048, 4096, 8192, 512, 256, 128.
      blocksize = 512;
      # prebuffer: How many milliseconds of data to keep on top of the blocksize.
      prebuffer = 20;
      # negotiate: Allow system audio driver to negotiate optimal rate and blocksize
      #            as close to the specified values as possible.
      negotiate = true;
    };

    midi = {
      # mididevice: Device that will receive the MIDI data (from the emulated MIDI
      #             interface - MPU-401). Choose one of the following:
      #             'fluidsynth', to use the built-in MIDI synthesizer. See the
      #                    [fluidsynth] section for detailed configuration.
      #             'mt32', to use the built-in Roland MT-32 synthesizer.
      #                    See the [mt32] section for detailed configuration.
      #             'auto', to use the first working external MIDI player. This
      #                    might be a software synthesizer or physical device.
      #             Possible values: auto, oss, alsa, fluidsynth, mt32, none.
      mididevice = "auto";
      # midiconfig: Configuration options for the selected MIDI interface.
      #             This is usually the id or name of the MIDI synthesizer you want
      #             to use (find the id/name with DOS command 'mixer /listmidi').
      #             - This option has no effect when using the built-in synthesizers
      #               (mididevice = fluidsynth or mt32).
      #             - When using ALSA, use Linux command 'aconnect -l' to list open
      #               MIDI ports, and select one (for example 'midiconfig=14:0'
      #               for sequencer client 14, port 0).
      #             - If you're using a physical Roland MT-32 with revision 0 PCB,
      #               the hardware may require a delay in order to prevent its
      #               buffer from overflowing. In that case, add 'delaysysex',
      #               for example: 'midiconfig=2 delaysysex'.
      #             See the README/Manual for more details.
      midiconfig = "";
      #     mpu401: Type of MPU-401 to emulate.
      #             Possible values: intelligent, uart, none.
      mpu401 = "intelligent";
    };

    fluidsynth = {
      # soundfont: Path to a SoundFont file in .sf2 format. You can use an
      #            absolute or relative path, or the name of an .sf2 inside
      #            the 'soundfonts' directory within your DOSBox configuration
      #            directory.
      #            An optional percentage will scale the SoundFont's volume.
      #            For example: 'soundfont.sf2 50' will attenuate it by 50 percent.
      #            The scaling percentage can range from 1 to 500.
      soundfont = "FluidR3_GM.sf2";
      #    chorus: Chorus effect: 'auto', 'on', 'off', or custom values.
      #            When using custom values:
      #              All five must be provided in-order and space-separated.
      #              They are: voice-count level speed depth modulation-wave, where:
      #              - voice-count is an integer from 0 to 99.
      #              - level is a decimal from 0.0 to 10.0
      #              - speed is a decimal, measured in Hz, from 0.1 to 5.0
      #              - depth is a decimal from 0.0 to 21.0
      #              - modulation-wave is either 'sine' or 'triangle'
      #              For example: chorus = 3 1.2 0.3 8.0 sine
      chorus = "auto";
      #    reverb: Reverb effect: 'auto', 'on', 'off', or custom values.
      #            When using custom values:
      #              All four must be provided in-order and space-separated.
      #              They are: room-size damping width level, where:
      #              - room-size is a decimal from 0.0 to 1.0
      #              - damping is a decimal from 0.0 to 1.0
      #              - width is a decimal from 0.0 to 100.0
      #              - level is a decimal from 0.0 to 1.0
      #              For example: reverb = 0.61 0.23 0.76 0.56
      reverb = "auto";
    };

    mt32 = {
      #  model: Model of synthesizer to use.
      #         'auto' picks the first model with available ROMs, in order as listed.
      #         'cm32l' and 'mt32' pick the first model of their type, in the order listed.
      #         'mt32_old' and 'mt32_new' are aliases for 1.07 and 2.04, respectively.
      #         Possible values: auto, cm32l, cm32l_102, cm32l_100, mt32, mt32_old, mt32_107, mt32_106, mt32_105, mt32_104, mt32_bluer, mt32_new, mt32_204.
      model = "auto";
      # romdir: The directory containing ROMs for one or more models.
      #         The directory can be absolute or relative, or leave it blank to
      #         use the 'mt32-roms' directory in your DOSBox configuration
      #         directory. Other common system locations will be checked as well.
      #         ROM files inside this directory may include any of the following:
      #           - MT32_CONTROL.ROM and MT32_PCM.ROM, for the 'mt32' model.
      #           - CM32L_CONTROL.ROM and CM32L_PCM.ROM, for the 'cm32l' model.
      #           - Unzipped MAME MT-32 and CM-32L ROMs, for the versioned models.
      romdir = "";
    };

    sblaster = {
      #   sbtype: Type of Sound Blaster to emulate. 'gb' is Game Blaster.
      #           Possible values: sb1, sb2, sbpro1, sbpro2, sb16, gb, none.
      sbtype = "sb16";
      #   sbbase: The IO address of the Sound Blaster.
      #           Possible values: 220, 240, 260, 280, 2a0, 2c0, 2e0, 300.
      sbbase = 220;
      #      irq: The IRQ number of the Sound Blaster.
      #           Possible values: 7, 5, 3, 9, 10, 11, 12.
      irq = 7;
      #      dma: The DMA number of the Sound Blaster.
      #           Possible values: 1, 5, 0, 3, 6, 7.
      dma = 1;
      #     hdma: The High DMA number of the Sound Blaster.
      #           Possible values: 1, 5, 0, 3, 6, 7.
      hdma = 5;
      #  sbmixer: Allow the Sound Blaster mixer to modify the DOSBox mixer.
      sbmixer = true;
      # sbwarmup: Silence initial DMA audio after card power-on, in milliseconds.
      #           This mitigates pops heard when starting many SB-based games.
      #           Reduce this if you notice intial playback is missing audio.
      sbwarmup = 100;
      #  oplmode: Type of OPL emulation. On 'auto' the mode is determined by 'sbtype'.
      #           All OPL modes are AdLib-compatible, except for 'cms'.
      #           Possible values: auto, cms, opl2, dualopl2, opl3, opl3gold, none.
      oplmode = "auto";
      #   oplemu: Provider for the OPL emulation. 'compat' provides better quality,
      #           'nuked' is the default and most accurate (but the most CPU-intensive).
      #           Possible values: default, compat, fast, mame, nuked.
      oplemu = "default";
    };

    gus = {
      #      gus: Enable Gravis UltraSound emulation.
      gus = false;
      #  gusbase: The IO base address of the Gravis UltraSound.
      #           Possible values: 240, 220, 260, 280, 2a0, 2c0, 2e0, 300.
      gusbase = 240;
      #   gusirq: The IRQ number of the Gravis UltraSound.
      #           Possible values: 5, 3, 7, 9, 10, 11, 12.
      gusirq = 5;
      #   gusdma: The DMA channel of the Gravis UltraSound.
      #           Possible values: 3, 0, 1, 5, 6, 7.
      gusdma = 3;
      # ultradir: Path to UltraSound directory. In this directory
      #           there should be a MIDI directory that contains
      #           the patch files for GUS playback. Patch sets used
      #           with Timidity should work fine.
      ultradir = "C:\\ULTRASND";
    };

    innovation = {
      #   sidmodel: Model of chip to emulate in the Innovation SSI-2001 card:
      #              - auto:  Selects the 6581 chip.
      #              - 6581:  The original chip, known for its bassy and rich character.
      #              - 8580:  A later revision that more closely matched the SID specification.
      #                       It fixed the 6581's DC bias and is less prone to distortion.
      #                       The 8580 is an option on reproduction cards, like the DuoSID.
      #              - none:  Disables the card.
      #             Possible values: auto, 6581, 8580, none.
      sidmodel = "none";
      #   sidclock: The SID chip's clock frequency, which is jumperable on reproduction cards.
      #              - default: uses 0.895 MHz, per the original SSI-2001 card.
      #              - c64ntsc: uses 1.023 MHz, per NTSC Commodore PCs and the DuoSID.
      #              - c64pal:  uses 0.985 MHz, per PAL Commodore PCs and the DuoSID.
      #              - hardsid: uses 1.000 MHz, available on the DuoSID.
      #             Possible values: default, c64ntsc, c64pal, hardsid.
      sidclock = "default";
      #    sidport: The IO port address of the Innovation SSI-2001.
      #             Possible values: 240, 260, 280, 2a0, 2c0.
      sidport = 280;
      "6581filter" = 50;
      "8580filter" = 50;
    };

    speaker = {
      #   pcspeaker: Enable PC-Speaker emulation.
      pcspeaker = true;
      #      pcrate: Sample rate of the PC-Speaker sound generation.
      pcrate = 18939;
      # zero_offset: Neutralizes and prevents the PC speaker's DC-offset from harming other sources.
      #              'auto' enables this for non-Windows systems and disables it on Windows.
      #              If your OS performs its own DC-offset correction, then set this to 'false'.
      #              Possible values: auto, true, false.
      zero_offset = "auto";
      #       tandy: Enable Tandy Sound System emulation. For 'auto', emulation is present only if machine is set to 'tandy'.
      #              Possible values: auto, on, off.
      tandy = "auto";
      #   tandyrate: Sample rate of the Tandy 3-Voice generation.
      #              Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
      tandyrate = 44100;
      #      disney: Enable Disney Sound Source emulation. (Covox Voice Master and Speech Thing compatible).
      disney = true;
      #    ps1audio: Enable IBM PS/1 Audio emulation.
      ps1audio = false;
    };

    joystick = {
      #  joysticktype: Type of joystick to emulate: auto (default),
      #                auto     : Detect and use any joystick(s), if possible.,
      #                2axis    : Support up to two joysticks.
      #                4axis    : Support the first joystick only.
      #                4axis_2  : Support the second joystick only.
      #                fcs      : Support a Thrustmaster-type joystick.
      #                ch       : Support a CH Flightstick-type joystick.
      #                hidden   : Prevent DOS from seeing the joystick(s), but enable them for mapping.
      #                disabled : Fully disable joysticks: won't be polled, mapped, or visible in DOS.
      #                (Remember to reset DOSBox's mapperfile if you saved it earlier)
      #                Possible values: auto, 2axis, 4axis, 4axis_2, fcs, ch, hidden, disabled.
      joysticktype = "auto";
      #         timed: enable timed intervals for axis. Experiment with this option, if your joystick drifts (away).
      timed = true;
      #      autofire: continuously fires as long as you keep the button pressed.
      autofire = false;
      #        swap34: swap the 3rd and the 4th axis. Can be useful for certain joysticks.
      swap34 = false;
      #    buttonwrap: enable button wrapping at the number of emulated buttons.
      buttonwrap = false;
      # circularinput: enable translation of circular input to square output.
      #                Try enabling this if your left analog stick can only move in a circle.
      circularinput = false;
      #      deadzone: the percentage of motion to ignore. 100 turns the stick into a digital one.
      deadzone = 10;
    };

    serial = {
      #       serial1: set type of device connected to com port.
      #                Can be disabled, dummy, modem, nullmodem, directserial.
      #                Additional parameters must be in the same line in the form of
      #                parameter:value. Parameter for all types is irq (optional).
      #                for directserial: realport (required), rxdelay (optional).
      #                                 (realport:COM1 realport:ttyS0).
      #                for modem: listenport sock (all optional).
      #                for nullmodem: server, rxdelay, txdelay, telnet, usedtr,
      #                               transparent, port, inhsocket, sock (all optional).
      #                SOCK parameter specifies the protocol to be used by both sides
      #                     of the conection. 0 for TCP and 1 for ENet reliable UDP.
      #                Example: serial1=modem listenport:5000 sock:1
      #                Possible values: dummy, disabled, modem, nullmodem, directserial.
      serial1 = "dummy";
      #       serial2: see serial1
      #                Possible values: dummy, disabled, modem, nullmodem, directserial.
      serial2 = "dummy";
      #       serial3: see serial1
      #                Possible values: dummy, disabled, modem, nullmodem, directserial.
      serial3 = "disabled";
      #       serial4: see serial1
      #                Possible values: dummy, disabled, modem, nullmodem, directserial.
      serial4 = "disabled";
      # phonebookfile: File used to map fake phone numbers to addresses.
      phonebookfile = "phonebook.txt";
    };

    dos = {
      #            xms: Enable XMS support.
      xms = true;
      #            ems: Enable EMS support. The default (=true) provides the best
      #                 compatibility but certain applications may run better with
      #                 other choices, or require EMS support to be disabled (=false)
      #                 to work at all.
      #                 Possible values: true, emsboard, emm386, false.
      ems = true;
      #            umb: Enable UMB support.
      umb = true;
      #            ver: Set DOS version (5.0 by default). Specify as major.minor format.
      #                 A single number is treated as the major version.
      #                 Common settings are 3.3, 5.0, 6.22, and 7.1.
      ver = "5.0";
      # keyboardlayout: Language code of the keyboard layout (or none).
      keyboardlayout = "auto";
    };

    ipx = {
      # ipx: Enable ipx over UDP/IP emulation.
      ipx = false;
    };

    autoexec = {
      # Lines in this section will be run at startup.
      # You can put your MOUNT lines here.
    };
  };
}
