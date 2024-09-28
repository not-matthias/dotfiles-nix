{...}: {
  imports = [(import ./hardware-configuration.nix)];

  # Only enable the services here, the settings are configured in the 'services/' folder.
  #
  services = {
    ollama.enable = true;
    miniflux.enable = true;
    self-hosted.enable = true;
    nfs.server = {
      enable = true;
      # fixed rpc.statd port; for firewall
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;
      exports = ''
        /mnt/data 127.0.0.1/24(insecure,ro,sync,no_subtree_check) 192.168.0.1/24(insecure,ro,sync,no_subtree_check) 100.121.111.38(insecure,ro,sync,no_subtree_check) 100.64.120.57(insecure,ro,sync,no_subtree_check)
        /mnt/data/test 127.0.0.1/24(insecure,ro,sync,no_subtree_check) 192.168.0.1/24(insecure,ro,sync,no_subtree_check) 100.121.111.38(insecure,ro,sync,no_subtree_check) 100.64.120.57(insecure,ro,sync,no_subtree_check)
      '';
    };
  };

  networking.firewall = {
    enable = true;
    # for NFSv3; view with `rpcinfo -p`
    allowedTCPPorts = [111 2049 4000 4001 4002 20048];
    allowedUDPPorts = [111 2049 4000 4001 4002 20048];
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

    # Enable swap on luks
    initrd = {
      luks.devices."luks-0d6a9387-fa29-4abb-b966-f619b3ababfc".device = "/dev/disk/by-uuid/0d6a9387-fa29-4abb-b966-f619b3ababfc";
    };
  };
}
