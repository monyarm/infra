{ pkgs, ... }:
{
  deadCells01 = pkgs.fetchurl {
    url = "https://motiontwin.com/img/presskit_dc/MasterArt_1080.jpg";
    sha256 = "0jgmb18rj1ah9b31cvqsb9xd19mv0x85kl6csvxp2xljcqfgz0ip";
  };

  deadCells02 = pkgs.fetchurl {
    url = "https://motiontwin.com/img/presskit_dc/OfficialKeyArt.jpg";
    sha256 = "1fyxknb081ip7s6j90pd0pannqnhnrjklnij5ma4n0b8la5k9zic";
  };

  deadCells03 = pkgs.fetchurl {
    url = "https://motiontwin.com/img/presskit_dc/MasterArt2_1080.jpg";
    sha256 = "06ll0swfvfxla3ibadq2v3klhhddrcqxbh4lv91qlb6i4pbfvp93";
  };

  deadCells04 = pkgs.fetchurl {
    url = "https://motiontwin.com/img/presskit_dc/AlternativeKeyArt.jpg";
    sha256 = "0pp52grb7jybhm0pp0llx2l735i53kdj3bkz0kyzvn6ngvdvjfsl";
  };
}
