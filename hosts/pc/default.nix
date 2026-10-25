{
  pkgs,
  unstable,
  user,
  flakes,
  lib,
  nixos-hardware,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
    flakes.win11-kvm.nixosModules.default
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  home-manager.users.${user} = {
    config,
    lib,
    ...
  }: {
    imports = [
      flakes.backhub.homeManagerModules.default
    ];
    home.stateVersion = "26.05";
    home.packages = with pkgs; [
      evince
      kdePackages.gwenview
      file-roller
      feishin
      ida-pro
      radius2
      unstable.amdtop
    ];
    backhub = {
      enable = true;
      # Provisioned outside this flake; contains only the raw GitHub token.
      secretFile = "/run/secrets/backhub-github-token";
      settings = {
        root = "${config.home.homeDirectory}/backups/backhub";
        source = {
          own = true;
          fork = true;
          star = true;
          gist = true;
          followers = true;
        };
      };
    };

    programs = {
      taskwarrior.enable = true;
      rclone.enable = true;
      plannotator.enable = true;
      ida-pro.enable = true;
      lmstudio = {
        enable = true;
        rocm.enable = true;
      };
      git.settings.commit.gpgsign = lib.mkForce false;
      ghostty.enable = true;
      rust = {
        enable = true;
        maintenance = {
          enable = true;
          sweep.scanPaths = [
            "${config.home.homeDirectory}/projects"
            "${config.home.homeDirectory}/work"
          ];
        };
      };
      niri-organize.enable = true;
      helix.enable = true;
      nixvim.enable = true;
      vscode.enable = true;
      binary-ninja = {
        enable = true;
        extensions = [
          pkgs.binja-wasm
          pkgs.binja-headless
          pkgs.binja-codemode-mcp
        ];
      };
      cli-agents = {
        claude.enable = true;
        herdr = {
          enable = true;
          github = [
            {
              # v1.6.0
              source = "AltanS/collie";
              rev = "2e3df8aa32e5306f8d945d6b3c2c134306976a41";
            }
            {
              # v0.4.0
              source = "kryptamine/herdr-auto-title";
              rev = "0f0026b0897f74e33f8809f3c48e3c631761a693";
            }
            {
              # 0.3.0, main (no release tags upstream)
              source = "plannotator/herdr-annotate";
              rev = "46cbf5dab1746dfeb46eb160c33990b0e0de15b0";
            }
            {
              # v0.1.0
              source = "devashish2203/herdr-worktrunk";
              rev = "8ceca541de8fb0d6006727e172534e1e2af17224";
            }
            {
              # v0.2.0, main (no release tags upstream)
              source = "ntindle/herdr-resurrect";
              rev = "5afa6755d4f35c62c7522ba4fd04922d1ac69602";
            }
          ];
        };
        pi-mono.enable = true;
        oh-my-pi = {
          enable = true;
          envFile = "/run/agenix/pi-mono-env";
        };
      };
      btop.enable = true;
      worktrunk.enable = true;
      helium.enable = true;
      minecraft.enable = true;
      discord = {
        enable = true;
        package = pkgs.discord.override {
          withVencord = true;
          withOpenASAR = true;
        };
      };
    };

    services = {
      activitywatch.enable = true;
      gpg-agent.enable = true;
    };

    # Client-only nix settings — these reach ~/.config/nix/nix.conf (via
    # home-manager), NOT the daemon's nix.custom.conf. For substituters
    # that must be queried during nixos-rebuild builds, add them to
    # hosts/configuration.nix nix.settings instead.
    nix.settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://install.determinate.systems"
        "https://helix.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    };
  };

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libevdev
        libdrm
        elfutils.out
        zlib
        zstd
        stdenv.cc.cc.lib
      ];
    };
    kache.enable = true;
    openclaw.enable = true;
    nix-index.enable = true;
    pay-respects.enable = true;
  };

  services = {
    language-study.enable = true;
    self-bot.enable = true;
    kaneo = {
      enable = true;
      publicUrl = "http://pc.ide-snares.ts.net:5173";
    };
    tuned = {
      enable = true;
      settings.dynamic_tuning = true;
      ppdSettings = {
        main.default = "performance";
        profiles = {
          power-saver = "powersave";
          balanced = "balanced";
          performance = "throughput-performance";
        };
      };
    };
    restic = {
      enable = true;
      localBackup.enable = true;
      remoteBackup.enable = false;
    };
    audiomuse-ai.enable = true;
    navidrome = {
      enable = true;
      musicFolder = "/home/${user}/Music";
      scrobblerUrl = "http://desktop.local:42010/apis/listenbrainz/1/";
      settings.Plugins = {
        Enabled = true;
        AutoReload = true;
        LogLevel = "info";
      };
    };
    octo-fiesta.enable = true;
    systembus-notify.enable = lib.mkForce true;
    vpn.enable = true;
  };

  hardware = {
    bluetooth.enable = true;
    sound.enable = true;
    ssd.enable = true;
  };

  services = {
    caddy.enable = true;
    taskwarrior-sync.enable = true;
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
  security.sudo.extraRules = [
    {
      users = [user];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  virtualisation = {
    podman.enable = true;
    qemu.enable = true;
  };

  specialisation.windows-vfio.configuration = {config, ...}: {
    virtualisation.win11-kvm = {
      enable = true;
      instrumentation = {
        enable = true;
        memflow.enable = true;
      };
      domain = {
        name = "win11";
        uuid = "e270b36a-1611-4003-9dbc-37a40921b16d";
      };
      settings = {
        memory_mib = 16384;
        cpu = {
          sockets = 1;
          cores = 12;
          threads = 2;
          affinity = {
            vcpus = [4 20 5 21 6 22 7 23 8 24 9 25 10 26 11 27 12 28 13 29 14 30 15 31];
            emulator = [0 16];
          };
        };
        debug_register_passthrough = true;
      };
      identity = {
        bios = {
          vendor = "INSYDE Corp.";
          version = "03.06";
        };
        system = {
          manufacturer = "Framework";
          product = "Desktop (AMD Ryzen AI Max 300 Series)";
          version = "A4";
          serial = "FRAMDACPA460230027";
          sku = "FRAMDACP04";
          family = "Desktop";
        };
        baseboard = {
          manufacturer = "Framework";
          product = "FRANMFCP04";
          version = "A4";
          serial = "FRANMFCPA4551200H7";
        };
        chassis = {
          manufacturer = "Framework";
          version = "A4";
          serial = "FRAMDACPA460230027";
        };
        acpi = {
          oem_id = "FRMWRK";
          oem_table_id = "FRANMFCP";
        };
        cpu = {
          manufacturer = "Advanced Micro Devices, Inc.";
          version = "AMD RYZEN AI MAX+ 395 w/ Radeon 8060S";
          serial = "AMD FWTR";
          asset = "AMD FWTS";
          part = "AMD FWTS";
        };
        memory = {
          manufacturer = "Micron Technology";
          serial = "000000004D543637";
          part = "MT62F2G32D4DS-023 WT";
          bank = "P0 CHANNEL A";
          loc_pfx = "DIMM";
          speed = 8000;
        };
      };
      disks = {
        system = {
          path = "/var/lib/libvirt/images/win11.qcow2";
          profile = flakes.win11-kvm.diskProfiles.crucial-mx500-250gb-hpa-128gib;
          serial = "2621E214B3A0"; # Change here; WWN and SMART-state path follow.
          # Use the new profile-qualified SMART path; preserve the old state file.
          boot_order = 1;
        };
        data = {
          path = "/var/lib/libvirt/images/win11-data.qcow2";
          profile = flakes.win11-kvm.diskProfiles.crucial-mx500-250gb-hpa-200gb;
          serial = "2644EA0E055D"; # Change here; WWN and SMART-state path follow.
        };
      };
      firmware = {
        # Keep the existing OVMF pair and NVRAM independent of patched QEMU.
        code_path = "${pkgs.qemu_kvm}/share/qemu/edk2-x86_64-secure-code.fd";
        vars_template_path = "${pkgs.qemu_kvm}/share/qemu/edk2-i386-vars.fd";
        nvram_path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
        installation_iso = null;
        secure_boot = true;
        tpm.type = "none";
      };
      passthrough = {
        gpu = {
          address = "0000:c2:00.0";
          rom_path = "/var/lib/libvirt/images/framework-03.06-1002-1586.rom";
        };
        audio = {
          address = "0000:c2:00.1";
          rom_path = "/var/lib/libvirt/images/framework-03.06-amd-gop.rom";
        };
        usb = [
          {
            vendor = lib.fromHexString "3434";
            product = lib.fromHexString "08a0";
          }
          {
            vendor = lib.fromHexString "046d";
            product = lib.fromHexString "c547";
          }
        ];
      };
      network = {
        enable = true;
        source = "default";
        model = "e1000e";
        mac = "02:9a:65:27:4c:b8";
      };
      devices = {
        virtual_display = "none";
        spice = false;
        usb_redirection = false;
        balloon = false;
      };
    };

    systemd.services.win11-autostart = {
      description = "Start Windows 11";
      wantedBy = ["multi-user.target"];
      requires = ["win11-kvm-define.service"];
      after = ["win11-kvm-define.service"];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.virtualisation.libvirtd.package}/bin/virsh --connect qemu:///system start ${config.virtualisation.win11-kvm.domain.name}";
      };
    };

    systemd.defaultUnit = lib.mkForce "multi-user.target";
  };

  desktop = {
    theme = "dark";
    niri.enable = true;
    fonts.enable = true;
  };

  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  networking = {
    hostName = "pc";
    networkmanager.enable = true;

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
