rec {
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
    # No nixpkgs.follows: pspdev.cachix.org is populated against the nixpkgs
    # revision pspdev-nix locks, so forcing ours re-hashes every toolchain
    # derivation and misses the cache entirely.
    pspdev-nix.url = "github:pspdev/pspdev-nix";
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
    # Old mame2010 core; newer segfaults arcade smoke. Only used for that pkg.
    nixpkgs-mame2010.url = "github:nixos/nixpkgs/4382ed2b7a6839d4280a9b386db49cbc5907414d";
    # Separate pin from determinate-nix above -- used for optimizePkgs.
    determinate-nix-optimize.url = "https://flakehub.com/f/DeterminateSystems/nix-src/=3.21.7";
    # Value FFI type + nix_wasm_init_v1 for builtins.wasm plugins. Source
    # only (flake = false); lib/wasm.nix vendors it as a Cargo dependency.
    nix-wasm-rust = {
      url = "github:DeterminateSystems/nix-wasm-rust";
      flake = false;
    };
    # Dynamic derivations must not change when the moving WASM support input
    # is updated. Bump this manually when the dynamic WASM ABI needs it.
    nix-wasm-rust-optimize = {
      url = "github:DeterminateSystems/nix-wasm-rust/c000d3992a7a9450c647c7bf7c3b6436790270e9";
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
    # Daily-updated AI CLIs (claude-code, opencode2, ...); used via overlay.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      # "https://nix-on-droid.cachix.org"
      "https://install.determinate.systems"
      "https://pspdev.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "nix-on-droid.cachix.org-1:56snoMJTXmE7wm+67YySRoTY64Zkivk9RT4QaKYgpkE="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "pspdev.cachix.org-1:lFw1M0EYJeN3Y2xHR7spiuPmThrNDXo8Z9I0Jgzig/0="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs =
    inputs':
    let
      inputs = inputs' // {
        self = inputs'.self // {
          inherit nixConfig;
        };
      };
      # Recursively overlays the decrypted contents of sources.sops.nix (any
      # private, sops-encrypted sources.*.sops.toml entries -- see
      # update-sources.py) onto the public sources.nix, when that file
      # exists. Same shape as lib/imports.nix's importSopsNix, duplicated
      # here (rather than threaded through customLib) because this runs
      # before perSystem's pkgs/customLib exist -- both call sites below
      # share this one function instead of re-deriving the merge twice.
      # sops from PATH (exec searches it): a nixpkgs import just for the
      # binary costs a whole extra nixpkgs eval.
      mergeSopsSources =
        publicSources:
        let
          privPath = ./sources.sops.nix;
        in
        if builtins.pathExists privPath then
          inputs.nixpkgs.lib.recursiveUpdate publicSources (
            builtins.exec [
              "sops"
              "--decrypt"
              (toString privPath)
            ]
          )
        else
          publicSources;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      _module.args.sources = mergeSopsSources (import ./sources.nix);
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
          sources = mergeSopsSources (import ./sources.nix);
          legacyPackages = import ./packages {
            inherit pkgs;
            inherit (pkgs) lib;
            inherit sources;
            craneLib = inputs.crane.mkLib pkgs;
            niccupLib = inputs.niccup.lib;
          };
          # Name-based, not value-based: isDerivation forces full
          # construction, cost ~8.6% of an eval. Add non-derivation
          # packages/*.nix names here; build fails loudly if you forget.
          nonDerivationPackageNames = [
            "builders"
          ];
          tests = import ./tests { inherit pkgs; };
          # Console deployment CLIs: psp-diff / psp-apply / psp-size.
          consoleTools = import ./apps/console/packages.nix {
            inherit (pkgs) lib python3;
            inherit pkgs;
          };
        in
        rec {
          inherit legacyPackages;
          packages =
            (pkgs.lib.filterAttrs (name: _: !(builtins.elem name nonDerivationPackageNames)) legacyPackages)
            // {
              inherit (consoleTools) psp-diff;
              inherit (consoleTools) psp-apply;
              inherit (consoleTools) psp-size;
            };

          apps = {
            psp-diff = {
              type = "app";
              program = "${consoleTools.psp-diff}/bin/psp-diff";
            };
            psp-apply = {
              type = "app";
              program = "${consoleTools.psp-apply}/bin/psp-apply";
            };
            psp-size = {
              type = "app";
              program = "${consoleTools.psp-size}/bin/psp-size";
            };
          };

          # Checks the filtered `packages`, not `legacyPackages` -- only
          # forced by `nix flake check`, not every eval.
          checks = tests // {
            packagesAreDerivations =
              assert pkgs.lib.all pkgs.lib.isDerivation (pkgs.lib.attrValues packages);
              pkgs.runCommand "check-packages-are-derivations" { } "touch $out";
          };

          topology.modules = [
            ./topology
            { inherit (inputs.self) nixosConfigurations; }
          ];
          treefmt = import ./treefmt.nix;
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              direnv
              nix-direnv # Added for optimized environment caching
              sops
              jq
              lgogdownloader
              depotdownloader
              innoextract
              p7zip
            ];

            shellHook = ''
              echo "❄️ Optimized Nix shell ready."
            '';
          };
        };
    };
}
