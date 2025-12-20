{ inputs, ... }:

let
  inherit (inputs)
    system-manager
    nixpkgs
    home-manager
    nix-topology
    ;
  inherit (nixpkgs) lib;

  # Import constants early to make dirs available
  constants = import ../lib/constants.nix { inherit lib; };
  inherit (constants) dirs;

  overlays = [
    inputs.nix-topology.overlays.default
    inputs.lix-module.overlays.default
    inputs.nh.overlays.default
    inputs.nur.overlays.default
    inputs.niri.overlays.niri
  ];

  pkgsGen =
    system:
    import nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
      };
    };

  # Import lib to get autoImport and other helpers
  # Use x86_64-linux pkgs as it's just for helper functions
  myLib = import ../lib/default.nix {
    pkgs = pkgsGen "x86_64-linux";
    system = "x86_64-linux";
    inherit lib;
    mkOutOfStoreSymlink = _: { };
  };
  inherit (myLib) autoImport;

  homeManagerModules = [
    inputs.stylix.homeModules.stylix
    inputs.niri.homeModules.niri
    inputs.niri.homeModules.stylix
    inputs.sops-nix.homeManagerModules.sops
    ./modules/lib.nix
    "${dirs.secrets}"
  ];

  commonModules = [
    inputs.sops-nix.nixosModules.sops
    ../secrets
    ./modules/lib.nix
  ];

  getSystemFromMeta = meta: meta.system or "x86_64-linux";

  loadMetaOrDefault = metaFile: if builtins.pathExists metaFile then import metaFile else { };

  getDirNames = dirSet: lib.attrNames (lib.filterAttrs (_name: type: type == "directory") dirSet);

  buildConfigurations =
    dirSet: builder:
    lib.foldl' (acc: name: acc // { "${name}" = builder name; }) { } (getDirNames dirSet);

  buildHomeConfig =
    userName:
    let
      userDir = ./home/${userName};
      meta = loadMetaOrDefault (userDir + "/meta.nix");
      currentSystem = getSystemFromMeta meta;
    in
    home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsGen currentSystem;
      extraSpecialArgs = {
        inherit inputs dirs autoImport;
        isNixOS = false;
        isHomeManager = true;
        isHomeManagerInNixOS = false;
      };
      modules = homeManagerModules ++ [
        ./modules/packages/nix.nix
        ./modules/filter.nix
        userDir
        "${dirs.secrets}/home.nix"
      ];
    };

  buildNixosConfig =
    hostName:
    let
      hostDir = ./nixos/${hostName};
      meta = loadMetaOrDefault (hostDir + "/meta.nix");
      currentSystem = getSystemFromMeta meta;
      hardwarePath =
        if builtins.pathExists (hostDir + "/hardware") then
          hostDir + "/hardware"
        else
          hostDir + "/hardware.nix";

      homeUsers = lib.genAttrs (getDirNames (builtins.readDir ./home)) (userName: ./home/${userName});
    in
    lib.nixosSystem {
      system = currentSystem;
      specialArgs = {
        inherit inputs dirs autoImport;
        isNixOS = true;
        isHomeManager = false;
        isHomeManagerInNixOS = true;
      };
      modules = commonModules ++ [
        (hostDir + "/configuration.nix")
        (if builtins.pathExists hardwarePath then hardwarePath else { })
        {
          networking.hostName = hostName;
          nixpkgs.pkgs = pkgsGen currentSystem;
        }
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs dirs;
              isNixOS = false;
              isHomeManager = true;
              isHomeManagerInNixOS = true;
            };
            sharedModules = homeManagerModules;
            users = homeUsers;
            backupFileExtension = "hmBackup";
          };
        }
        nix-topology.nixosModules.default
      ];
    };

  buildSystemConfig =
    hostName:
    let
      hostDir = ./system/${hostName};
      meta = loadMetaOrDefault (hostDir + "/meta.nix");
      currentSystem = getSystemFromMeta meta;
    in
    system-manager.lib.makeSystemConfig {
      modules = commonModules ++ [
        (hostDir + "/configuration.nix")
        ../secrets/system.nix
        {
          _module.args = {
            inherit dirs autoImport;
            isNixOS = true;
            isHomeManager = false;
            isHomeManagerInNixOS = true;
          };
          nixpkgs.hostPlatform = currentSystem;
          nixpkgs.pkgs = pkgsGen currentSystem;
        }
        (
          { lib, ... }:
          {
            options = {
              system = lib.mkOption { type = lib.types.raw; };
              services.openssh.enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };
            };
          }
        )
      ];
    };

  homeConfigurations = buildConfigurations (builtins.readDir ./home) buildHomeConfig;
  nixosConfigurations = buildConfigurations (builtins.readDir ./nixos) buildNixosConfig;
  systemConfigs = buildConfigurations (builtins.readDir ./system) buildSystemConfig;

in
{
  flake = {
    inherit nixosConfigurations systemConfigs homeConfigurations;
    lib.overlays = overlays;
  };
}
