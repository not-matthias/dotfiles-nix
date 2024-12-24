{
  user,
  pkgs,
  unstable,
  ...
}: {
  imports = [(import ./hardware-configuration.nix)];

  home-manager.users.${user} = {
    # Only enable when using Hyprland
    home.packages = with pkgs; [
      unstable.zed-editor
      vlc
      evince
      gwenview
      nautilus
      file-roller
    ];

    programs = {
      alacritty.enable = true;
      minecraft.enable = true;
      neovim.enable = true;
    };
  };

  # Only enable the services here, the settings are configured in the 'services/' folder.
  #
  services = {
    caddy.enable = true;
    ollama = {
      enable = true;
      useNvidia = true;
    };
    miniflux.enable = true;
    firefly-iii.enable = false;
    self-hosted.enable = true;
    nfs.enable = true;
    adguardhome.enable = true;
    memos.enable = true;
    scrutiny.enable = true;
    #netdata.enable = true;
    homepage-dashboard.enable = true;
    paperless.enable = true;
    gitea.enable = true;
    watchyourlan = {
      enable = true;
      ifaces = "enp34s0";
    };
  };

  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
  };

  desktop = {
    hyprland = {
      enable = true;
      useNvidia = true;
    };
    fonts.enable = true;
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
  };
  users.users.${user}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2yZENvNlZ8XQxcPVG8CrSEaUmvthPwheHRruEKqnzP not-matthias@raspi"
  ];

  # TODO: Change to hardware.virtualization
  virtualisation = {
    docker = {
      enable = true;
      enableNvidia = true;
    };
  };

  boot = {
    luks-remote = {
      enable = true;
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDvED6PbgTV9/yjDymEci/ATe6vQDb9c11hqUwNyEStvFmkDr5ili7+2fiUhTrNaefTX5RaDIRaKBu4jl+kjSn5tfv+lvdYbl/UM8yMN8YODcM4JbAUo5cyX76s5BXaBrqQH0TGEXhKlLkVdxCJCBLm9tpakkxgLruj0qEwSoSGruM/QCYgbhXrh9NcEtOBaOBZ39DUhT3MEKgZJBlbqIXqyeHN5L1GLBEgBN73dZhh7fsJdIpfaezqzIeu8FQnAnL94eOFlDx7PXm1Wiacpcb5S7GsIFnd1iEc/TlYyaXKN+12VK2qPe6KMZfF7lBvgnjEU868sHiU8OXpWkYWQ3RJs0uQqSylQum8jsJAOWcygavVRrOO+zDxzNkPXa+7H3Jah9XoywaKjz8rsPTs0qu/AWZG/KyV7EeQu+J6oIOXGv2OBcndRuQTBKIimHCdnGEnpgkAzw9gs14oc0MN97k1izb5zyK6zf4jsD8cHl+64Hevapto28yqcCanQk9p9+M= not-matthias@laptop"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2yZENvNlZ8XQxcPVG8CrSEaUmvthPwheHRruEKqnzP not-matthias@raspi"
      ];
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Enable swap on luks
    initrd.luks.devices."luks-0d6a9387-fa29-4abb-b966-f619b3ababfc".device = "/dev/disk/by-uuid/0d6a9387-fa29-4abb-b966-f619b3ababfc";
  };
}
