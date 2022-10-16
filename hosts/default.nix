{
  lib,
  inputs,
  nixpkgs,
  home-manager,
  nur,
  user,
  location,
  hyprland,
  fenix,
  ...
}: let
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  lib = nixpkgs.lib;
in {
  desktop = lib.nixosSystem {
    inherit system;
    specialArgs = {inherit inputs user location hyprland;};
    modules = [
      ({...}: {nixpkgs.overlays = [fenix.overlay];})
      ./desktop
      ./configuration.nix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {inherit user;};
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./desktop/home.nix)];
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
        home-manager.extraSpecialArgs = {inherit user;};
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./laptop/home.nix)];
        };
      }
    ];
  };
}
