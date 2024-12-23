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
    #netdata.enable = true;
    caddy.enable = true;
    homepage-dashboard.enable = true;
    paperless.enable = true;
  };

  programs = {
    neovim.enable = true;
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

            # Raspi
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDSvx25Wt0l7y8WX80R695BBSGOGvpTUnBRWY8LxHxoyX7nzWx0Y13mde1rkCKmn74SiIYnmPV6iaXgEJKz8woNFlU8QbfoZReH3DWWEAkmj7UuhF7jrd2otEq1otmcacXOhGvxqVHNO9fD+cow37bbDiBs4vQr7ECo0c2PO5XRRa1EL3RTX2uDDd5XxXq1TJtvsvuL6RfAVR+D3R7HWOwIqzyxnbDqOlOqXiLSUk0DmsxSptVkwkj1z1SCHidhZm4GPlXVq0nlCM+8E0hJfASHh+L31WC2C/3JOkWa6C82k1Q95PcNKY4PoFkxREH6BslB1p9ct3tVboYM4afWdPEWAr9lSUIFovG4zlyfQs160z5R6IS3svpAbK5mKYuVwflSuzU+Bq/aSZ+7nmRtQUxRglmtAHW7vlFVdQYUCQB2qKs8ZT2CTQBkaG+aD90v32HqZUKTFWAxmwtQPcgoB8QsYsbWsiMnT+/9K+Xvml+D8t13wUgcaNhguQUT6m71IQOiG+DzQguRxI1+owKAiJ8ObYpdqEz+9ofezox3ucFZ9xmk2fmH/G3wt2vUvz0Zo5F7vnBcr84DVrraWBW/d+DcyNhweASoaTzUUmI5+zZiEd+Ixm2eZJ4eCRwvJx1x0AzKCR5j26o43P+QNr75T+ylXmEDh4+8r62bnV5zadxCNQ== root@nixos"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII6AjHb77flaA6EN+9Wxsx27oCbAA0pRJsnyvMK2Lrp2 root@nixos"
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
