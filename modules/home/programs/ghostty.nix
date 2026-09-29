{
  config,
  unstable,
  ...
}: {
  programs.ghostty = {
    package = unstable.ghostty;
    systemd.enable = true;
    enableFishIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;
    settings = {
      font-family = [
        config.stylix.fonts.monospace.name
        config.stylix.fonts.emoji.name
      ];
      font-size = config.stylix.fonts.sizes.terminal;
      window-padding-x = 5;
      window-padding-y = 5;
      confirm-close-surface = false;
      keybind = [
        "ctrl+enter=unbind"
        "ctrl+tab=unbind"
        "ctrl+shift+tab=unbind"
      ];
      mouse-scroll-multiplier = "precision:0.5,discrete:0.5";
    };
  };
}
