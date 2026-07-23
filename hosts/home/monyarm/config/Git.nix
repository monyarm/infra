{ user, ... }: {
  programs.git = {
    enable = true;
    signing = {
      signByDefault = true;
    };
    settings = {
      user = {
        name = user.fullName;
        inherit (user) email;
      };
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
      core = {
        autocrlf = "input";
        trustctime = false;
        ignorecase = false;
        editor = "nano";
      };
      pull = {
        rebase = false;
      };
      credential = {
        helper = "store";
      };
      http = {
        postBuffer = 524288000;
      };
    };
  };
}
