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
    # nix-wine = {
    #   url = "path:/home/monyarm/Documents/nix-wine";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    steam-fetcher = {
      url = "github:nix-community/steam-fetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # packages/minijson.nix's dub-to-nix-at-build-time step -- dynamic
    # derivations without a committed lockfile.
    drowse = {
      url = "github:figsoda/drowse";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # packages/maxima-cli.nix -- static Rust build (Cargo.lock hand-committed,
    # see packages/maxima-cli-cargo-lock.nix), no dynamic-derivation codegen.
    crane.url = "github:ipetkov/crane";

    determinate-nix = {
      url = "https://flakehub.com/f/DeterminateSystems/nix-src/*";
      # inputs.nixpkgs.follows = "nixpkgs";
      # inputs.flake-parts.follows = "flake-parts";
      # follows omitted to allow use of substituters
    };
    # Own pin, not `follows` -- avoids invalidating already-optimized files
    # on unrelated nixpkgs bumps. Bump manually.
    optimize-nixpkgs.url = "github:nixos/nixpkgs/1d4e0f865d68258aada31e68e6d79c8c463f3b34";
    # Separate pin from determinate-nix above -- used for optimizePkgs.
    determinate-nix-optimize.url = "https://flakehub.com/f/DeterminateSystems/nix-src/=3.21.7";
    # Value FFI type + nix_wasm_init_v1 for builtins.wasm plugins. Source
    # only (flake = false); lib/wasm.nix vendors it as a Cargo dependency.
    nix-wasm-rust = {
      url = "github:DeterminateSystems/nix-wasm-rust";
      flake = false;
    };

    rom = {
      url = "github:manic-systems/rom";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hiccup-style HTML generation, used by hosts/home/monyarm/games/Steam/report.nix
    # (and available repo-wide as the `niccup` lib arg -- see hosts/modules/lib.nix).
    niccup = {
      url = "github:embedding-shapes/niccup";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      # "https://nix-on-droid.cachix.org"
      "https://install.determinate.systems"

    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-on-droid.cachix.org-1:56snoMJTXmE7wm+67YySRoTY64Zkivk9RT4QaKYgpkE="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      _module.args.sources = import ./sources.nix;
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
            config.allowUnfree = true;
          };
          sources = import ./sources.nix;
          legacyPackages = import ./packages {
            inherit pkgs;
            inherit (pkgs) lib;
            inherit sources;
            drowseSrc = inputs.drowse;
            craneLib = inputs.crane.mkLib pkgs;
            niccupLib = inputs.niccup.lib;
          };
          # Name-based, not value-based: isDerivation forces full
          # construction, cost ~8.6% of an eval. Add non-derivation
          # packages/*.nix names here; build fails loudly if you forget.
          nonDerivationPackageNames = [ "minijson-dub-lock" ];
        in
        rec {
          inherit legacyPackages;
          packages = pkgs.lib.filterAttrs (
            name: _: !(builtins.elem name nonDerivationPackageNames)
          ) legacyPackages;

          # Checks the filtered `packages`, not `legacyPackages` -- only
          # forced by `nix flake check`, not every eval.
          checks.legacyPackagesAreDerivations =
            assert pkgs.lib.all pkgs.lib.isDerivation (pkgs.lib.attrValues packages);
            pkgs.runCommand "check-legacyPackages-are-derivations" { } "touch $out";

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
                "**/*.sops.nix"
                ".claude/skills/**"

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
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              direnv
              nix-direnv # Added for optimized environment caching
              sops
              jq
            ];

            shellHook = ''
              echo "❄️ Optimized Nix shell ready."
            '';
          };
        };
    };
}
