{pkgs, ...}: let
  bleachhack = builtins.fetchurl {
    url = "https://github.com/BleachDev/BleachHack/releases/download/1.2.6/bleachhack-1.19.1.jar";
    sha256 = "sha256:1b91aqq8lfwpw5xck67k0fl4psnw5pn0rbakg4z2ifr1c4c5kzpg";
  };
in {
  home.packages = with pkgs; [
    prismlauncher
  ];

  home.file.".local/share/PrismLauncher/instances/1.19.2/.minecraft/mods/bleachhack-1.19.1.jar".source = bleachhack;
}
