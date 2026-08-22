{
  fetchSteam,
  splitFilesWith,
  image,
  ...
}:
with image;
{
  skullgirls =
    let
      files = [
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_CFDC_Jon02_LRG.png";
          transform = crop16x9South;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_CFDC_Brian02_LRG.png";
          transform = crop16x9North;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Evo_Shirt_2014_2_LRG.png";
          transform = grow16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Eightysixed_Shirt_Valentines_Day_LRG.png";
          transform = grow16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_MobileLaunch2017.png";
          transform = grow16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Valentine_Valentines_Day_LRG.png";
          transform =
            img:
            img
            |> removeBackground {
              coordinates = [
                {
                  x = 2249;
                  y = 2428;
                }
              ];
              fillColor = "#6b6f79";
            }
            |> grow16x9' "#6b6f79";
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_CFDC_Brian03_LRG.png";
          transform = growEdge16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Shirt_SG_BacktoSchool_LRG.png";
          transform = crop16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_CFDC_Jon01_LRG.png";
          transform = crop16x9North;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_SGM_Birthday2020_Cerebella_Sairus.png";
          transform = grow16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Evo_Shirt_Concept_LRG.png";
          transform =
            img:
            img
            |> transform {
              args = "-gravity west -crop 50%x100%";
              nameSuffix = "half";
              extension = "png";
            }
            |> removeBackground { }
            |> grow16x9' "#d02e31";
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_CFDC_Alex01_LRG.png";
          transform = crop16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Cancer_Drive_LRG.png";
          transform = crop16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Evo_Shirt_LRG.png";
          transform = grow16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_StreamBlackDahlia.png";
          transform = crop16x9North;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Shirt_SG_Halloween_LRG.png";
          transform = grow16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_CFDC_04LRG.png";
          transform = grow16x9North;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_CFDC_Brian01_LRG.png";
          transform = crop16x9North;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_SGM_Birthday2020_RoboFortune_Sairus.png";
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_SGM_Birthday2020_Valentine_Sairus.png";
          transform = crop16x9South;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Valentine_ValentinesDay_Nightgown_LRG.png";
          transform = crop16x9North;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_Evo_Shirt_2014_LRG.png";
          transform = grow16x9;
        }
        {
          file = "Digital Art Compendium/Production Art/ProductionArt_CFDC_LRG.png";
          transform = crop16x9North;
        }
      ];
    in
    fetchSteam {
      appId = 245170;
      depotId = 1549100;
      manifestId = 8133640707689963864;
      sha256 = "sha256-hfQfPNrKAGoZyLi7TvIXSvvxMBIX8JDjEhm4O9g4Z1I="; # TODO: update hash
      filelist = map ({ file, ... }: file) files;
    }
    |> splitFilesWith files;
}
