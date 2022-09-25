{
  description = "Personal flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
        url = "github:nix-community/NUR";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let 
      system = "x86_64-linux";
      username = "not-matthias";
      lib = nixpkgs.lib;

    in {
      # nixosConfigurations.nixbox = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [ 
      #     ./configuration.nix
      #   ];
      # };

      homeConfigurations = {
        ${username} = home-manager.lib.homeManagerConfiguration {
          system = "x86_64-linux";
          homeDirectory = "/home/${username}";
          username = "${username}";
          configuration.imports = [ ./home.nix ];
        };
      };
    };
}
