# treefmt-nix module; shared by flake formatter and flake-closure.nix
{ pkgs, ... }:
let
  shellFiles = [
    "*.sh"
    "*.zsh"
  ];
in
{
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    "node_modules/**"
    ".bench/**"
    "hosts/home/*/config/JetBrains/*/**"
    "**/.github/**"
    "**/*.sops.nix"
    ".claude/skills/**"
    ".claude/agents/**"
    "hosts/home/monyarm/config/AI/Claude/memory/**"
  ];
  # nix
  programs.nixfmt.enable = true;
  programs.deadnix.enable = true;
  programs.statix.enable = true;
  # markdown
  programs.mdformat.enable = true;
  programs.mdsh.enable = true;
  # css/json/js
  programs.prettier.enable = true;
  programs.prettier.includes = [
    "*.json"
    "*.css"
    "*.js"
  ];
  # shell
  programs.shellcheck.enable = true;
  programs.shellcheck.includes = shellFiles;
  programs.shellcheck.excludes = [
    "hosts/home/monyarm/config/ZSH/.p10k.zsh"
  ];
  programs.shfmt.enable = true;
  programs.shfmt.includes = shellFiles;
  programs.shfmt.excludes = [
    "hosts/home/monyarm/config/ZSH/.p10k.zsh"
  ];
  # py
  programs.mypy.enable = true;
  programs.mypy.directories = {
    "hosts/home/monyarm/config/Bin/.local/bin" = {
      extraPythonPackages = with pkgs.python3.pkgs; [ ];
    };
  };
  programs.ruff-check.enable = true;
  programs.ruff-format.enable = true;
  programs.isort.enable = true;
  # yaml
  programs.yamlfmt.enable = true;
  # toml
  programs.taplo.enable = true;
  # rust
  programs.rustfmt.enable = true;
  programs.rustfmt.edition = "2021";
  # generic text/config
  programs.keep-sorted.enable = true;
  # xml
  programs.xmllint.enable = true;
  # qml
  settings.formatter."qmlformat" = {
    command = "${pkgs.kdePackages.qtdeclarative}/bin/qmlformat";
    options = [
      "--inplace"
      "--normalize"
    ];
    includes = [ "*.qml" ];
  };
}
