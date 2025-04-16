{unstable, ...}: {
  programs.zoxide = {
    enable = true;
    package = unstable.zoxide;
    enableFishIntegration = true;
    options = [
      "--cmd j"
    ];
  };
}
