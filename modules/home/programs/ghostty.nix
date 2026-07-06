{unstable, ...}: {
  programs.ghostty = {
    package = unstable.ghostty;
    systemd.enable = true;
    enableFishIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;
    settings = {
      window-padding-x = 5;
      window-padding-y = 5;
      confirm-close-surface = false;
      keybind = "ctrl+enter=ignore";
    };
  };
}
