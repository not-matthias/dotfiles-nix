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
    firefly-iii.enable = false;
    self-hosted.enable = true;
    nfs.enable = false;
    adguardhome.enable = true;
    adguardhome.useDns = false;
    memos.enable = true;
    scrutiny.enable = true;
    netdata.enable = true;
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

  virtualisation = {
    docker = {
      enable = true;
      enableNvidia = true;
    };

    # qemu.enable = false;
    # single-gpu-passthrough.enable = false;
    # vfio = {
    #   enable = false;
    #   IOMMUType = "amd";
    #   # devices = ["10de:1f08" "10de:10f9"];
    #   # ignoreMSRs = true;
    #   # disableEFIfb = true;
    #   loadVfioPci = true;
    #   # blacklistNvidia = true;
    #   # enableNestedVirt = true;
    # };
  };

  # Lots of these are from the default `configuration.nix`
  boot.kernelParams = ["ip=dhcp"];
  networking.nameservers = ["1.1.1.1" "1.0.0.1"];
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
          enable = true;
          port = 22;
          authorizedKeys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDvED6PbgTV9/yjDymEci/ATe6vQDb9c11hqUwNyEStvFmkDr5ili7+2fiUhTrNaefTX5RaDIRaKBu4jl+kjSn5tfv+lvdYbl/UM8yMN8YODcM4JbAUo5cyX76s5BXaBrqQH0TGEXhKlLkVdxCJCBLm9tpakkxgLruj0qEwSoSGruM/QCYgbhXrh9NcEtOBaOBZ39DUhT3MEKgZJBlbqIXqyeHN5L1GLBEgBN73dZhh7fsJdIpfaezqzIeu8FQnAnL94eOFlDx7PXm1Wiacpcb5S7GsIFnd1iEc/TlYyaXKN+12VK2qPe6KMZfF7lBvgnjEU868sHiU8OXpWkYWQ3RJs0uQqSylQum8jsJAOWcygavVRrOO+zDxzNkPXa+7H3Jah9XoywaKjz8rsPTs0qu/AWZG/KyV7EeQu+J6oIOXGv2OBcndRuQTBKIimHCdnGEnpgkAzw9gs14oc0MN97k1izb5zyK6zf4jsD8cHl+64Hevapto28yqcCanQk9p9+M= not-matthias@laptop"
          ];
          hostKeys = [
            "/etc/ssh/ssh_host_rsa_key"
          ];
        };
      };

      # Enable swap on luks
      luks.devices."luks-0d6a9387-fa29-4abb-b966-f619b3ababfc".device = "/dev/disk/by-uuid/0d6a9387-fa29-4abb-b966-f619b3ababfc";
    };
  };
}
