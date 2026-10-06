{ user, ... }: {
  programs.git = {
    enable = true;
    signing = {
      signByDefault = true;
    };

    # Adds git-lfs to home.packages AND generates the [filter "lfs"] section
    # itself, so the hand-written one in settings below is redundant -- keeping
    # both would emit a duplicate section into the same generated gitconfig.
    lfs.enable = true;

    settings = {
      user = {
        name = user.fullName;
        inherit (user) email;
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
