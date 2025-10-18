# NOTE: Currently not using this because there's a huge delay (1s+) on startup.
{unstable, ...}: {
  programs.ghostty = {
    package = unstable.ghostty;
    enableFishIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;
    settings = {
      window-padding-x = 5;
      window-padding-y = 5;
      confirm-close-surface = false;
    };
  };
}
