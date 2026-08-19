{ fetchGitTree, sources, ... }:
let
  mattpocockSkills = fetchGitTree sources.ai.skills.mattpocock-skills;
in
{
  ai.skills = {
    # SKILL.md is a one-line delegator ("Call the Skill tool with \"grilling\"") --
    # both entries are required for it to do anything.
    grill-me = "${mattpocockSkills}/skills/productivity/grill-me";
    grilling = "${mattpocockSkills}/skills/productivity/grilling";
  };
}
