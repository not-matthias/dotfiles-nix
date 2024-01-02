{lib, ...}: {
  imports = [(import ./hardware-configuration.nix)];

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };
  hardware.intel.enable = true;
  virtualisation.vfio = {
    enable = true;
    IOMMUType = "intel";
    enableNestedVirt = true;
  };

  boot = {
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    initrd = {
      # Setup keyfile
      secrets."/crypto_keyfile.bin" = null;

      # Enable swap on luks
      luks.devices."luks-482bfe5c-c987-4a97-9c07-b8cd312cabb5".device = "/dev/disk/by-uuid/482bfe5c-c987-4a97-9c07-b8cd312cabb5";
      luks.devices."luks-482bfe5c-c987-4a97-9c07-b8cd312cabb5".keyFile = "/crypto_keyfile.bin";
    };
  };

  services.fstrim.enable = true;
  services.thermald.enable = true;

  # TODO: Further configs
  # https://github.com/nzbr/nixos/blob/cd219d6e0bd968f749cd74a9289800b9e67775c0/module/pattern/laptop.nix#L13-L22
  # https://github.com/krebs/stockholm/blob/40f103e9ccf99dc36c92e2e008ed7a0b3dca1f48/makefu/2configs/hw/tp-x2x0.nix#L41-L50

  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
      START_CHARGE_THRESH_BAT0 = 90;
      STOP_CHARGE_THRESH_BAT0 = 97;
      RUNTIME_PM_ON_BAT = "auto";
    };
  };
  services.auto-cpufreq = {
    enable = true;
    # https://github.com/AdnanHodzic/auto-cpufreq/blob/master/auto-cpufreq.conf-example
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
      battery = {
        governor = "powersave";
        turbo = "auto";
      };
    };
  };
  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave";
  };

  #temporary bluetooth fix
  systemd.tmpfiles.rules = [
    "d /var/lib/bluetooth 700 root root - -"
  ];
  systemd.targets."bluetooth".after = ["systemd-tmpfiles-setup.service"];
}
