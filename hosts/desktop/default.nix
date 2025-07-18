{user, ...}: {
  imports = [(import ./hardware-configuration.nix)];

  # Only disable when using a desktop environment:
  # desktop = {
  #   hyprland = {
  #     enable = true;
  #     useNvidia = true;
  #   };
  #   fonts.enable = true;
  # };
  #
  home-manager.users.${user} = {
    #   home.packages = with pkgs; [
    #     unstable.zed-editor
    #
    #     vlc
    #     evince
    #     gwenview
    #     nautilus
    #     file-roller
    #     gnome-text-editor
    #     mission-center
    #   ];
    #
    programs = {
      nixvim.enable = true;
      #alacritty.enable = true;
      #waybar.enable = true;
      #firefox.enable = true;
    };
  };

  # Only enable the services here, the settings are configured in the 'services/' folder.
  services = {
    restic = {
      enable = true;
      localBackup = {
        enable = true;
        schedule = "daily";
        # TODO: Create zfs pool for backups and set repo
      };
      # remoteBackup = {
      #   enable = true;
      # repository = "s3:s3.eu-central-003.backblazeb2.com/desktop-71bc7ce26f614b13";
      #   schedule = "weekly";
      # };
    };

    n8n.enable = true;
    audiobookshelf = {
      enable = true;
      audioFolder = "/mnt/data/personal/audiobooks/";
    };
    caddy.enable = true;
    ollama = {
      enable = true;
      useNvidia = true;
    };
    miniflux.enable = true;
    adguardhome.enable = false;
    memos.enable = true;
    scrutiny.enable = true;
    homepage-dashboard.enable = true;
    paperless.enable = true;
    gitea.enable = true;
    restic.server.enable = true;
    navidrome = {
      enable = true;
      musicFolder = "/mnt/data/personal/music";
      scrobblerUrl = "http://localhost:42010/apis/listenbrainz/1/";
    };
    maloja.enable = true;
    crm.enable = true;
    kokoro = {
      enable = true;
      useGpu = false;
    };
    tandoor-recipes.enable = true;
    jellyfin.enable = true;
    karakeep.enable = true;
    nocodb.enable = true;
    nitter.enable = true;
    redlib.enable = true;
  };

  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
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
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDvED6PbgTV9/yjDymEci/ATe6vQDb9c11hqUwNyEStvFmkDr5ili7+2fiUhTrNaefTX5RaDIRaKBu4jl+kjSn5tfv+lvdYbl/UM8yMN8YODcM4JbAUo5cyX76s5BXaBrqQH0TGEXhKlLkVdxCJCBLm9tpakkxgLruj0qEwSoSGruM/QCYgbhXrh9NcEtOBaOBZ39DUhT3MEKgZJBlbqIXqyeHN5L1GLBEgBN73dZhh7fsJdIpfaezqzIeu8FQnAnL94eOFlDx7PXm1Wiacpcb5S7GsIFnd1iEc/TlYyaXKN+12VK2qPe6KMZfF7lBvgnjEU868sHiU8OXpWkYWQ3RJs0uQqSylQum8jsJAOWcygavVRrOO+zDxzNkPXa+7H3Jah9XoywaKjz8rsPTs0qu/AWZG/KyV7EeQu+J6oIOXGv2OBcndRuQTBKIimHCdnGEnpgkAzw9gs14oc0MN97k1izb5zyK6zf4jsD8cHl+64Hevapto28yqcCanQk9p9+M= not-matthias@laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2yZENvNlZ8XQxcPVG8CrSEaUmvthPwheHRruEKqnzP not-matthias@raspi"
  ];

  age.identityPaths = ["/etc/ssh/ssh_host_rsa_key"];

  programs = {
    sccache.enable = true;
  };

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
