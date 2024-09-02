{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nurpkgs.url = github:nix-community/NUR;
    home-manager.url = "github:nix-community/home-manager/release-24.05";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv.url = "github:cachix/devenv/latest";
    nixvim.url = "github:nix-community/nixvim/nixos-24.05";
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    nurpkgs,
    home-manager,
    nur,
    fenix,
    devenv,
    nixvim,
    ...
  } @ flakes: let
    user = "not-matthias";
  in {
    nixosConfigurations = (
      import ./hosts {
        inherit (nixpkgs) lib;
        inherit flakes nixpkgs nixpkgs-unstable nurpkgs home-manager nur user fenix devenv nixvim;
      }
    );
  };
}
