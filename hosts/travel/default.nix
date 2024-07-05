{...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };
  hardware = {
    powersave.enable = true;
    intel.enable = true;
  };
  desktop.hyprland.enable = true;

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 2;
    };
    efi.canTouchEfiVariables = true;
  };

  services.fstrim.enable = true;
}
