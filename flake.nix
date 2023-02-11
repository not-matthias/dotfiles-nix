{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nurpkgs = {
      url = github:nix-community/NUR;
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    spicetify-nix = {
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jetbrains-updater = {
      url = "gitlab:genericnerdyusername/jetbrains-updater";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv/latest";
    };
  };

  outputs = {
    nixpkgs,
    nurpkgs,
    home-manager,
    nur,
    hyprland,
    fenix,
    spicetify-nix,
    jetbrains-updater,
    devenv,
    ...
  } @ flakes: let
    user = "not-matthias";
    location = "~/.config/nixpkgs";
  in {
    nixosConfigurations = (
      import ./hosts {
        inherit (nixpkgs) lib;
        inherit flakes nixpkgs nurpkgs home-manager nur user location hyprland fenix spicetify-nix jetbrains-updater devenv;
      }
    );
  };
}
