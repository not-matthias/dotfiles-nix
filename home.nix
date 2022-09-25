{ ... }: {
  programs.home-manager.enable = true;

   home.packages = [
    pkgs.cowsay
  ];

  programs.git = {
    enable = true;
  };
}