{
  flakes,
  nixpkgs,
  nurpkgs,
  home-manager,
  user,
  fenix,
  spicetify-nix,
  devenv,
  hyprland,
  nixvim,
  ...
}: let
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };

  nur = import nurpkgs {
    inherit pkgs;
    nurpkgs = pkgs;
  };

  fontsOverlay = import (
    builtins.fetchTarball {
      url = "https://github.com/dimitarnestorov/nix-google-fonts-overlay/archive/master.tar.gz";
      sha256 = "sha256:1ay7y6l0h8849md36ljc4mgpj7gkfvbimz17vzbm92kl4p7grm1g";
    }
  );
  overlays = [
    fenix.overlays.default
    fontsOverlay
    (_: prev: {
      inherit (devenv.packages."${prev.system}") devenv;
    })
  ];

  commonModules = [
    (import ../modules/overlays/pkgs.nix)
    {
      nixpkgs.overlays = overlays;
    }
    home-manager.nixosModules.home-manager
    hyprland.nixosModules.default

    ./configuration.nix
  ];

  nixosBox = arch: base: name:
    base.lib.nixosSystem {
      system = arch;
      specialArgs = {
        inherit flakes user hyprland nixvim;
      };
      modules =
        commonModules
        ++ [
          # System configuration
          (./. + "/${name}")

          # Home configuration
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit flakes user spicetify-nix nixvim;
                addons = nur.repos.rycee.firefox-addons;
              };
              users.${user} = {
                imports = [
                  ./home.nix
                  spicetify-nix.homeManagerModule
                  hyprland.homeManagerModules.default
                  nixvim.homeManagerModules.nixvim
                ];
              };
            };
          }
        ];
    };

  lib = nixpkgs.lib;
in {
  desktop = nixosBox "x86_64-linux" nixpkgs "desktop";
  laptop = nixosBox "x86_64-linux" nixpkgs "laptop";
  framework = nixosBox "x86_64-linux" nixpkgs "framework";
}
