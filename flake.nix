{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nurpkgs = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    hyprland,
    ...
  }: let
    system = "x86_64-linux";
    hostName = "nixos";
    username = "not-matthias";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    #        nixosConfigurations = {
    #          ${hostName} = nixpkgs.lib.nixosSystem {
    #            inherit system;
    ##            modules = [ ./system/configuration.nix ];
    #          };
    #        };
    homeManagerConfiguration = {
      ${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home/home.nix

          hyprland.homeManagerModules.default
          {wayland.windowManager.hyprland.enable = true;}
        ];
      };
    };
  };
}
