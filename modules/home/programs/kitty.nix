# NOTE: Currently not using this because I'd have to handle xterm-kitty everywhere. Also,
#       I can't easily use `clear` which is super annoying.
{...}: {
  programs.kitty = {
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
    };
    shellIntegration.enableFishIntegration = true;
  };
}
