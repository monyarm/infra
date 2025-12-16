{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-mod-manager = {
      url = "github:Nowaaru/nix-mod-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-wine = {
      url = "path:/home/monyarm/Documents/nix-wine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };
    nix-topology.url = "github:oddlama/nix-topology";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nix-on-droid.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-on-droid.cachix.org-1:56snoMJTXmE7wm+67YySRoTY64Zkivk9RT4QaKYgpkE="
    ];
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.nix-topology.flakeModule
        ./hosts
      ];

      perSystem =
        {
          system,
          ...
        }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            inherit (inputs.self.lib) overlays;
          };
        in
        {
          topology.modules = [
            ./topology
            { inherit (inputs.self) nixosConfigurations; }
          ];
          treefmt =
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
                "hosts/home/*/config/GIMP/.config/GIMP/*/**"
                "hosts/home/*/config/JetBrains/*/**"
                "**/.github/**"

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
              programs.ruff.enable = true;
              programs.isort.enable = true;
              # yaml
              programs.yamlfmt.enable = true;
              # toml
              programs.taplo.enable = true;
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
            };
        };
    };
}
