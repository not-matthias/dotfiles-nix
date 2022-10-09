{
  config,
  pkgs,
  ...
}: {
  nix.settings.auto-optimise-store = true;

  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
  ];

  # Fonts: https://github.com/notusknot/dotfiles-nix/blob/main/modules/system/configuration.nix#L16

  # Nix settings, auto cleanup and enable flakes
  nix = {
    settings.auto-optimise-store = true;
    settings.allowed-users = ["not-matthias"];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
