{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # keep-sorted start
    appimage-run
    bat
    bc
    curl
    diskus
    entr
    eza
    file
    git
    gnupg
    htop
    inotify-tools
    jq
    p7zip
    ripgrep
    rs
    socat
    sqlite
    sshfs
    tree
    unrar
    unzip
    wget
    # keep-sorted end
  ];
}
