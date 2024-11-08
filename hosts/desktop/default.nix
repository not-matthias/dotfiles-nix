{...}: {
  imports = [(import ./hardware-configuration.nix)];

  # Only enable the services here, the settings are configured in the 'services/' folder.
  #
  services = {
    ollama = {
      enable = true;
      useNvidia = true;
    };
    miniflux.enable = true;
    self-hosted.enable = true;
    nfs.enable = true;
  };

  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
  };

  desktop.hyprland = {
    enable = false;
    useNvidia = true;
  };

  hardware = {
    nvidia.enable = true;
    zfs.enable = true;
    ssd.enable = true;
  };

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
    #permitRootLogin = "yes";
  };

  # virtualisation = {
  #   single-gpu-passthrough.enable = true;
  #   vfio = {
  #     enable = true;
  #     IOMMUType = "amd";
  #     # devices = ["10de:1f08" "10de:10f9"];
  #     # ignoreMSRs = true;
  #     # disableEFIfb = true;
  #     loadVfioPci = true;
  #     # blacklistNvidia = true;
  #     # enableNestedVirt = true;
  #   };
  # };

  # Lots of these are from the default `configuration.nix`
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      # Remote disk unlocking: https://nixos.wiki/wiki/Remote_disk_unlocking#Usage
      availableKernelModules = ["r8169"]; # Find with: lspci -v | grep -iA8 'network\|ethernet'
      systemd.users.root.shell = "/bin/cryptsetup-askpass";
      network = {
        enable = true;
        ssh = {
          enable = false;
          port = 22;
          # TODO:
          # authorizedKeys = [ "ssh-rsa AAAAyourpublic-key-here..." ];
          # hostKeys = [ "/etc/secrets/initrd/ssh_host_rsa_key" ];
        };
      };

      # Enable swap on luks
      luks.devices."luks-0d6a9387-fa29-4abb-b966-f619b3ababfc".device = "/dev/disk/by-uuid/0d6a9387-fa29-4abb-b966-f619b3ababfc";
    };
  };
}
