{ pkgs, ... }:
{
  jojoGroup = pkgs.fetchurl {
    name = "jojo-group.jpg";
    url = "https://pbs.twimg.com/media/FQJmx8baUAIRE4_?format=jpg&name=large";
    sha256 = "sha256-aOWeZrPFBBWmQW8oxLTYGq+55AeTygEJUb39B1A+QdA=";
  };
}
