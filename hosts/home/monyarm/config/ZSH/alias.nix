{ lib, ... }:
let
  # Generate cd aliases for going up directories
  cdUpAliases =
    let
      mkCdUp = n: builtins.concatStringsSep "/" (lib.replicate n "..");
      mkAlias = nameFn: n: {
        name = nameFn n;
        value = "cd ${mkCdUp n}";
      };
      mkDotAlias = mkAlias (n: lib.concatStrings (lib.replicate n "."));
      mkNumAlias = mkAlias (n: ".${toString n}");
      rangeDot = lib.range 3 12;
      rangeNum = lib.range 1 12;
    in
    {
      "cd.." = "cd ..";
    }
    // lib.listToAttrs (map mkDotAlias rangeDot)
    // lib.listToAttrs (map mkNumAlias rangeNum);
in
{
  programs.zsh.shellAliases = lib.mkMerge [
    {
      c = "clear";
      path = "echo -e \${PATH//:/\\\\n}";
      now = "date +\"%T\"";
      nowtime = "now";
      nowdate = "date +\"%d-%m-%Y\"";

      # untar
      untar = "tar -zxvf";

      ## set some other defaults ##
      df = "df -H";
      du = "du -ch";

      ## Use a long listing format ##
      ll = "ls -la";

      ## Show hidden files ##
      "l." = "ls -d .* --color=auto";

      ## Start calculator with math support
      bc = "bc -l";

      ## Create parent directories on demand
      mkdir = "mkdir -pv";

      # install  colordiff package :)
      diff = "colordiff";

      ## Make mount command output pretty and human readable format

      mount = "mount | column -t";

      ## Resume wget by default
      wget = "wget -c";

      gitpush = "git-push-prepost";

      dummy = "truncate -s 0";
      esync = "emaint -a sync";

      ph = "phoronix-test-suite";

      abcde = "abcde -S 45";
    }
    cdUpAliases
    # Generate grep aliases with --color=auto
    (lib.genAttrs [ "grep" "egrep" "fgrep" ] (cmd: "${cmd} --color=auto"))
  ];
}
