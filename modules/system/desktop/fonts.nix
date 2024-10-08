{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      carlito # NixOS
      vegur # NixOS
      source-code-pro
      jetbrains-mono
      font-awesome # Icons
      corefonts # MS
      (nerdfonts.override {
        # Nerdfont Icons override
        fonts = [
          "FiraCode"
          "RobotoMono"
        ];
      })
      (google-fonts.override {fonts = ["Poppins"];})
    ];

    fontconfig = {
      enable = true;
      antialias = true;
      hinting.enable = false;
      subpixel.lcdfilter = "default";
    };
  };
}
