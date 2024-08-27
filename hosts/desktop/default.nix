{...}: {
  imports = [(import ./hardware-configuration.nix)];

  # TODO: Move to self-hosted folder
  services.paperless = {
    enable = true;
    port = 11432;
  };

  services.outline = {
    enable = false;
    port = 11431;
  };

  services.gitea = {
    enable = true;
    settings.server.HTTP_PORT = 11430;
  };

  services.adguardhome = {
    enable = false;
    host = "0.0.0.0";
    port = 11429;
    # TODO: openFirewall?
  };

  services.jellyfin = {
    enable = true;
    # openFirewall
    #port = 11429;
  };
  services.jellyseerr = {
    enable = true;
    port = 5055;
  };

  services.home-assistant = {
    enable = true;
    config.http.server_port = 8123;
  };

  services.tailscale = {
    enable = true;
  };

  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
    firewall = {
      allowedTCPPorts = [
        # Allow RDP and VNC
        3389
        5900
      ];
    };
  };

  desktop.hyprland = {
    enable = true;
    useNvidia = true;
  };

  hardware.nvidia.enable = true;
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
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
      };
    };

    # Enable swap on luks
    initrd = {
      luks.devices."luks-0d6a9387-fa29-4abb-b966-f619b3ababfc".device = "/dev/disk/by-uuid/0d6a9387-fa29-4abb-b966-f619b3ababfc";
    };
  };
}
