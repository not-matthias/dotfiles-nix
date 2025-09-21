{pkgs, ...}: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # Allow both fingerprint and password authentication
      auth-method = "both";
      # Show text prompt for password fallback
      show-failed-attempts = true;
    };
  };
}
