{lib, ...}: {
  gtk = {
    enable = true;
    theme = lib.mkForce null;
    iconTheme = lib.mkForce null;
  };
}
