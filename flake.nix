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

  outputs = { self, nixpkgs, home-manager, nur, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "not-matthias";
      hostname = "desktop";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
      };

#      # This lets us reuse the code to "create" a system
#      # Credits go to sioodmy on this one!
#      # https://github.com/sioodmy/dotfiles/blob/main/flake.nix
#      mkSystem = pkgs: system: hostname:
#          pkgs.lib.nixosSystem {
#              system = system;
#              modules = [
#                  { networking.hostName = hostname; }
#                  # General configuration (users, networking, sound, etc)
#                  ./modules/system/configuration.nix
#                  # Hardware config (bootloader, kernel modules, filesystems, etc)
#                  # DO NOT USE MY HARDWARE CONFIG!! USE YOUR OWN!!
#                  (./. + "/hosts/${hostname}/hardware-configuration.nix")
#                  home-manager.nixosModules.home-manager
#                  {
#                      home-manager = {
#                          useUserPackages = true;
#                          useGlobalPkgs = true;
#                          extraSpecialArgs = { inherit inputs; };
#                          # Home manager config (configures programs like firefox, zsh, eww, etc)
#                          users.notus = (./. + "/hosts/${hostname}/user.nix");
#                      };
#                  }
#              ];
#              specialArgs = { inherit inputs; };
#          };
    in {
      formatter.${system} = pkgs.nixpkgs-fmt;

#      nixosConfiguration = {
#        # Now, defining a new system is can be done in one line
#        #                                Architecture   Hostname
#        laptop = mkSystem inputs.nixpkgs "x86_64-linux" "laptop";
#        desktop = mkSystem inputs.nixpkgs "x86_64-linux" "desktop";
#      };
#
#      homeConfigurations.${hostname} = home-manager.lib.homeManagerConfiguration {
#        inherit pkgs;
#
#        modules = [
#          ./home.nix
#        ];
#      };
    };
}
