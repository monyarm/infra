{ fetchGOG, ... }:
let
  teenagent = fetchGOG {
    game = "teenagent";
    fileId = "en1installer0";
    sha256 = "sha256-RzEDcLdSp2gKvWeHAJWdRhPRyzQObrSaX+Bdb9VmU2E=";
  };

  ultima4 = fetchGOG {
    game = "ultima_iv_quest_of_the_avatar";
    fileId = "en1installer0";
    sha256 = "sha256-dW2BmATKhtLXTIjJE2aIDpd5wRQ3teICzYsxStCttvo=";
  };

  dragonsphere = fetchGOG {
    game = "dragonsphere";
    fileId = "en1installer0";
    sha256 = "sha256-vaB3evCzpUuzo5Y1qLcxa2iwTdxplqfEgCdX3PlJqLk=";
  };

  martianDreams = fetchGOG {
    game = "ultima_worlds_of_adventure_2_martian_dreams";
    fileId = "en1installer0";
    sha256 = "sha256-3YdzHQX0TXvVNXawhd2qoFAbFx+xFI7DAyO6W6jG/DU=";
  };

  bladeRunner = fetchGOG {
    game = "blade_runner";
    fileId = [
      "en1installer0"
      "en1installer1"
    ];
    sha256 = "sha256-ZZUz4TGdl5DB8vDd0eDgzMdXaHbWJ3BpKhGrULj/6+0=";
  };

  grimFandango = fetchGOG {
    game = "grim_fandango_remastered";
    fileId = [
      "en1installer0"
      "en1installer1"
    ];
    sha256 = "sha256-37LX6R7vyYIqIfOZQAh9QCrVNqhI29MGiB1rFouhDsk=";
  };

  bladeRunnerEE = fetchGOG {
    game = "blade_runner_enhanced_edition_base";
    fileId = [
      "en1installer0"
      "en1installer1"
      "en1installer2"
    ];
    sha256 = "sha256-5Hl8ejvD7pbVD+CA+1D4Rivq7jsi4BeGs/nN8IsMVsk=";
  };

  conquestsOfCamelot = fetchGOG {
    game = "conquests_of_camelot";
    fileId = "en1installer0";
    sha256 = "sha256-A9Y7GkZKcZLnINWNVEaTHIt+R4/wp+Zbk7lVyvPDY44=";
  };

  conquestsOfTheLongbow = fetchGOG {
    game = "conquests_of_the_longbow";
    fileId = "en1installer0";
    sha256 = "sha256-fObJ1tJNMqcsR52VSWJGSCSWZrp1e9LqwZ3QIHmaf1g=";
  };

  returnOfThePhantom = fetchGOG {
    game = "return_of_the_phantom";
    fileId = "en1installer0";
    sha256 = "sha256-z6vW43W2VjxW4JfPenUuByF4BaCEh9zc5RhH/5BTfjw=";
  };

  daggerOfAmonRa = fetchGOG {
    game = "the_dagger_of_amon_ra";
    fileId = "en1installer0";
    sha256 = "sha256-7oQX9WKFIjjc1pmI5ag+FJHCBkzsDj15cN2iWbCB2Oc=";
  };

  torinsPassage = fetchGOG {
    game = "torins_passage";
    fileId = "en1installer0";
    sha256 = "sha256-snp6YKb8+zjhgyEJk8j9Oo+VwAxuIPrqvHPNzAt6+Ss=";
  };

  beneathASteelSky = fetchGOG {
    game = "beneath_a_steel_sky";
    fileId = "en1installer0";
    sha256 = "sha256-CEjidQErxanbXpIiq6SxzCnKwlZEdL5+cCaha84ZfaU=";
  };

  flightOfTheAmazonQueen = fetchGOG {
    game = "flight_of_the_amazon_queen";
    fileId = "en1installer0";
    sha256 = "sha256-Egml84/1hn9zHXFNPJOb5bpZ3qTJCJLS+1PBYF8P6rQ=";
  };

  lureOfTheTemptress = fetchGOG {
    game = "lure_of_the_temptress";
    fileId = "en1installer0";
    sha256 = "sha256-OWbjC0aXIP43ri37W5t8+5DEg56Y9F/+lhpia61LZE4=";
  };

  savageEmpire = fetchGOG {
    game = "worlds_of_ultima_the_savage_empire";
    fileId = "en1installer0";
    sha256 = "sha256-4ICpc69t8OCA1jEgEtfzguJNyXj8o5BsVXbOAS4OmJ0=";
  };
in
{
  games.scummvm.games = {
    teenagent = {
      engineid = "teenagent";
      guioptions = "sndNoSpeech sndNoMIDI";
      extra = "Alt version";
      description = "Teen Agent";
      path = "${teenagent}";
    };

    ultima4Enh = {
      gameid = "ultima4_enh";
      engineid = "ultima";
      guioptions = "sndNoSpeech";
      description = "Ultima IV - Quest of the Avatar - Enhanced";
      path = "${ultima4}";
    };

    dragonsphere = {
      engineid = "mads";
      description = "Dragonsphere";
      path = "${dragonsphere}/DRAGON";
    };

    martianDreams = {
      gameid = "martiandreams";
      engineid = "ultima";
      description = "Ultima: Worlds of Adventure 2 - Martian Dreams";
      path = "${martianDreams}/MARTIAN";
    };

    bladeRunner = {
      engineid = "bladerunner";
      description = "Blade Runner";
      path = "${bladeRunner}";
    };

    grimFandango = {
      engineid = "grim";
      description = "Grim Fandango Remastered";
      path = "${grimFandango}/app";
    };

    bladeRunnerEE = {
      gameid = "bladerunner-ee";
      engineid = "bladerunner";
      description = "Blade Runner - Enhanced Edition";
      path = "${bladeRunnerEE}";
    };

    conquestsOfCamelot = {
      gameid = "camelot";
      engineid = "sci";
      description = "Conquests of Camelot";
      path = "${conquestsOfCamelot}";
    };

    conquestsOfTheLongbow = {
      gameid = "longbow";
      engineid = "sci";
      description = "Conquests of the Longbow";
      path = "${conquestsOfTheLongbow}";
    };

    returnOfThePhantom = {
      gameid = "phantom";
      engineid = "mads";
      description = "Return of the Phantom";
      path = "${returnOfThePhantom}/RotP/RESOURCE";
    };

    daggerOfAmonRa = {
      gameid = "laurabow2";
      engineid = "sci";
      description = "The Dagger of Amon Ra";
      path = "${daggerOfAmonRa}";
    };

    torinsPassage = {
      gameid = "torin";
      engineid = "sci";
      description = "Torin's Passage";
      path = "${torinsPassage}";
    };

    beneathASteelSky = {
      engineid = "sky";
      extra = "v0.0372 cd";
      description = "Beneath a Steel Sky";
      alt_intro = false;
      path = "${beneathASteelSky}";
    };

    flightOfTheAmazonQueen = {
      engineid = "queen";
      extra = "Talkie";
      guioptions = "gameOption1";
      description = "Flight of the Amazon Queen";
      alt_intro = false;
      path = "${flightOfTheAmazonQueen}";
    };

    lureOfTheTemptress = {
      gameid = "lure_1";
      engineid = "lure";
      extra = "VGA";
      guioptions = "sndNoSpeech gameOption1";
      tts_narrator = false;
      description = "Lure of the Temptress";
      path = "${lureOfTheTemptress}";
    };

    savageEmpire = {
      gameid = "thesavageempire";
      engineid = "ultima";
      description = "Worlds of Ultima: The Savage Empire";
      path = "${savageEmpire}/SAVAGE";
    };
  };
}
