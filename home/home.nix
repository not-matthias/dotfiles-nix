{
  nixpkgs,
  config,
  pkgs,
  ...
}: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "not-matthias";
  home.homeDirectory = "/home/not-matthias";

  nixpkgs.config.allowUnfree = true;

  # TODO: Needs to be added to global configuration.nix
  # See: https://github.com/nix-community/home-manager/issues/2424
  #	programs.dconf.enable = true;

  # TODO: https://github.com/yrashk/nix-home/blob/master/home.nix#L65
  home.packages = with pkgs; [
    fish

    # Tools
    exa
    bottom
    btop
    tokei
    alejandra

    # Dev
    jetbrains-mono
#    jetbrains.clion # TODO: Enable unfree
  ];

  # TODO: https://github.com/yrashk/nix-home/blob/master/home.nix#L156
  programs.git = {
    enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  imports = (import ./programs) ++ (import ./services);
}
