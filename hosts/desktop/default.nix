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

  # Keep track of SMART data
  services.scrutiny = {
    enable = true;
    collector.enable = true;
    settings.web.listen.port = 11428;
    settings.notify.urls = [
      "ntfy://ntfy.sh/desktop-zfs"
    ];
  };

  # Don't need this because of scrutiny
  # services.smartd = {
  #   enable = true;
  #   autodetect = true;
  #   extraOptions = ["--interval=7200"];
  #   notifications.test = true;
  #   notifications.wall.enable = true;
  #   notifications.x11.enable = true;
  # };

  # TODO: Works with free version as well
  # services.ntfy-sh = {
  #   enable = true;
  #   # https://docs.ntfy.sh/config/#config-options
  #   settings = {
  #     listen-http = "127.0.0.1:2586";
  #     base-url = "http://localhost";
  #   };
  # };

  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
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
