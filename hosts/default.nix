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
  ...
}: let
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      nurpkgs.overlay
    ];
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
      ({...}: {nixpkgs.overlays = [fenix.overlay];})
      hyprland.nixosModules.default
      ./desktop
      ./configuration.nix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user;
          addons = nur.repos.rycee.firefox-addons;
        };
        home-manager.users.${user} = {
          imports = [
            ./home.nix
            ./desktop/home.nix
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
      ({...}: {nixpkgs.overlays = [fenix.overlay];})
      #   hyprland.nixosModules.default
      ./laptop
      ./configuration.nix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user spicetify-nix;
          addons = nur.repos.rycee.firefox-addons;
        };
        home-manager.users.${user} = {
          imports = [
            ./home.nix
            ./laptop/home.nix
            spicetify-nix.homeManagerModule
          ];
        };
      }
    ];
  };
}
