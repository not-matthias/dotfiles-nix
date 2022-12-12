{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nurpkgs.url = github:nix-community/NUR;
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix.url = "github:the-argus/spicetify-nix";
  };

  outputs = inputs @ {
    nixpkgs,
    nurpkgs,
    home-manager,
    nur,
    hyprland,
    fenix,
    spicetify-nix,
    ...
  }: let
    user = "not-matthias";
    location = "~/.config/nixpkgs";
  in {
    nixosConfigurations = (
      import ./hosts {
        inherit (nixpkgs) lib;
        inherit inputs nixpkgs nurpkgs home-manager nur user location hyprland fenix spicetify-nix;
      }
    );
  };
}
