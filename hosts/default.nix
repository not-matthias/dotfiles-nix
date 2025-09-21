{
  flakes,
  nixpkgs,
  nixpkgs-unstable,
  nurpkgs,
  home-manager,
  user,
  fenix,
  nixvim,
  nixos-hardware,
  arion,
  agenix,
  stylix,
  quickshell,
  niri,
  ...
}: let
  nixosBox = arch: base: name: domain: let
    system = arch;

    pkgs = import base {
      inherit system overlays;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-31.7.7"
        ];
      };
    };

    stable = import nixpkgs {
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
    ];

    commonModules = [
      (import ../modules/overlays/pkgs.nix)
      {
        nixpkgs.overlays = overlays;
      }
      home-manager.nixosModules.home-manager
      arion.nixosModules.arion
      agenix.nixosModules.default
      stylix.nixosModules.stylix
      flakes.determinate.nixosModules.default

      ./configuration.nix
    ];
  in
    base.lib.nixosSystem {
      system = arch;
      specialArgs = {
        inherit flakes user domain nixvim stable unstable nixos-hardware stylix quickshell niri;
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
                inherit flakes user nixvim stable unstable stylix;
                addons = nur.repos.rycee.firefox-addons;
              };
              users.${user} = {
                imports = [
                  ./home.nix
                  nixvim.homeManagerModules.nixvim
                  agenix.homeManagerModules.age
                  flakes.vicinae.homeManagerModules.default
                ];
              };
            };
          }
        ];
    };
in {
  desktop = nixosBox "x86_64-linux" nixpkgs "desktop" "desktopnm.duckdns.org";
  framework = nixosBox "x86_64-linux" nixpkgs "framework" "laptopnm.duckdns.org";
  raspi = nixosBox "aarch64-linux" nixpkgs "raspi" "raspi.ide-snares.ts.net";

  # Old configs:
  # laptop = nixosBox "aarch64" nixpkgs "laptop" "localhost";
  # travel = nixosBox "x86_64-linux" nixpkgs "travel" "laptop.local";
}
