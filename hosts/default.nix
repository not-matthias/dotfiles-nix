{
  flakes,
  nixpkgs,
  nixpkgs-unstable,
  nurpkgs,
  home-manager,
  user,
  fenix,
  devenv,
  nixvim,
  nixos-hardware,
  arion,
  ...
}: let
  nixosBox = arch: base: name: domain: let
    system = arch;

    pkgs = import nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };

    unstable = import nixpkgs-unstable {
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
      arion.nixosModules.arion

      ./configuration.nix
    ];
  in
    base.lib.nixosSystem {
      system = arch;
      specialArgs = {
        inherit flakes user domain nixvim unstable nixos-hardware;
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
              backupFileExtension = "backup";
              extraSpecialArgs = {
                inherit flakes user nixvim unstable;
                addons = nur.repos.rycee.firefox-addons;
              };
              users.${user} = {
                imports = [
                  ./home.nix
                  nixvim.homeManagerModules.nixvim
                ];
              };
            };
          }
        ];
    };
in {
  desktop = nixosBox "x86_64-linux" nixpkgs "desktop" "desktop.local";
  framework = nixosBox "x86_64-linux" nixpkgs "framework" "laptop.local";
  raspi = nixosBox "aarch64-linux" nixpkgs "raspi" "raspi.local";

  # Old configs:
  # laptop = nixosBox "aarch64" nixpkgs "laptop" "localhost";
  # travel = nixosBox "x86_64-linux" nixpkgs "travel" "localhost";
}
