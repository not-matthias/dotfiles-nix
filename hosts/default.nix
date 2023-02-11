{
  inputs,
  nixpkgs,
  nurpkgs,
  home-manager,
  user,
  location,
  hyprland,
  fenix,
  spicetify-nix,
  jetbrains-updater,
  devenv,
  ...
}: let
  system = "x86_64-linux";

  overlays = [
    fenix.overlays.default
    # nurpkgs.overlay
    (_: prev: {
      inherit (devenv.packages."${prev.system}") devenv;
    })
  ];

  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };

  nur = import nurpkgs {
    inherit pkgs;
    nurpkgs = pkgs;
  };

  lib = nixpkgs.lib;
in {
  desktop = lib.nixosSystem {
    inherit system;
    specialArgs = {inherit inputs user location hyprland;};
    modules = [
      {
        nixpkgs.overlays = overlays;
      }
      jetbrains-updater.nixosModules.jetbrains-updater
      hyprland.nixosModules.default
      ./desktop
      ./configuration.nix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user spicetify-nix hyprland;
          addons = nur.repos.rycee.firefox-addons;
        };
        home-manager.users.${user} = {
          imports = [
            ./home.nix
            spicetify-nix.homeManagerModule
          ];
        };
      }
    ];
  };

  laptop = lib.nixosSystem {
    inherit system;
    specialArgs = {inherit inputs user location hyprland;};
    modules = [
      ({...}: {
        nixpkgs.overlays = [
          fenix.overlays.default
        ];
      })
      jetbrains-updater.nixosModules.jetbrains-updater
      hyprland.nixosModules.default
      ./laptop
      ./configuration.nix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user spicetify-nix hyprland;
          addons = nur.repos.rycee.firefox-addons;
        };
        home-manager.users.${user} = {
          imports = [
            ./home.nix
            spicetify-nix.homeManagerModule
          ];
        };
      }
    ];
  };

  framework = lib.nixosSystem {
    inherit system;
    specialArgs = {inherit inputs user location hyprland;};
    modules = [
      ({...}: {
        nixpkgs.overlays = [
          fenix.overlays.default
        ];
      })
      jetbrains-updater.nixosModules.jetbrains-updater
      hyprland.nixosModules.default
      ./framework
      ./configuration.nix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user spicetify-nix hyprland;
          addons = nur.repos.rycee.firefox-addons;
        };
        home-manager.users.${user} = {
          imports = [
            ./home.nix
            spicetify-nix.homeManagerModule
          ];
        };
      }
    ];
  };
}
