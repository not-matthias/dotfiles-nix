# WiFi Performance Optimization Module
# Optimizes WiFi performance for Intel iwlwifi cards, particularly on Framework laptops
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.wifi-performance;
in {
  options.hardware.wifi-performance = {
    enable = lib.mkEnableOption "WiFi Performance Optimization";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      iw
      wirelesstools
      wavemon
      iperf3
    ];

    boot.extraModprobeConfig = ''
      # Intel WiFi performance optimizations
      # Disable power saving for maximum performance
      options iwlwifi power_save=0

      # Enable 802.11n/ac features
      options iwlwifi 11n_disable=0 swcrypto=0

      # Optimize for throughput over latency
      options iwlwifi amsdu_size=3

      # Enable antenna aggregation for better signal
      options iwlwifi antenna=0x3

      # Framework-specific optimizations
      options iwlwifi remove_when_gone=0
      options iwlwifi power_scheme=1

      # Disable LED blinking to save CPU cycles
      options iwlwifi led_mode=0

      # Enable BT coexistence for better WiFi performance when Bluetooth is active
      options iwlwifi bt_coex_active=1
    '';

    # NetworkManager optimizations
    networking.networkmanager = {
      wifi = {
        # Use iwd backend for better performance
        backend = "iwd";
        # Increase scan interval for better battery life without major performance impact
        scanRandMacAddress = false;
        # Enable power saving only when idle
        powersave = false;
      };
      settings = {
        wifi = {
          # Optimize scanning behavior
          scan-rand-mac-address = "no";
          # Prefer 5GHz networks
          scan-generate-mac-address-mask = "FE:FF:FF:00:00:00";
        };
        connection = {
          # Faster connection establishment
          "wifi.cloned-mac-address" = "preserve";
        };
        ipv4 = {
          # Reduce DHCP timeout for faster connections
          dhcp-timeout = 30;
        };
        ipv6 = {
          dhcp-timeout = 30;
        };
        device = {
          # Optimize WiFi device behavior
          "wifi.scan-rand-mac-address" = "no";
        };
      };
    };

    # iwd configuration for better performance
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General = {
          # Enable address randomization
          AddressRandomization = "network";
          # Use all available bands
          DisableBandWidth = false;
          # Enable roaming
          EnableNetworkConfiguration = true;
        };
        Network = {
          # Enable IPv6
          EnableIPv6 = true;
          # Fast transition for enterprise networks
          NameResolvingService = "systemd";
        };
        Scan = {
          # Disable periodic scanning when connected
          DisablePeriodicScan = false;
          # Initial periodic scan interval
          InitialPeriodicScanInterval = 10;
          # Maximum periodic scan interval
          MaxPeriodicScanInterval = 300;
        };
        Rank = {
          # Prefer 5GHz networks
          BandModifier5Ghz = 1.2;
          # Boost signal strength importance
          SignalStrengthModifier = 1.0;
        };
      };
    };

    # Kernel parameters for networking performance
    boot.kernel.sysctl = {
      # Increase network buffer sizes
      "net.core.rmem_max" = lib.mkForce 134217728;
      "net.core.wmem_max" = lib.mkForce 134217728;
      "net.core.rmem_default" = lib.mkForce 262144;
      "net.core.wmem_default" = lib.mkForce 262144;

      # TCP optimizations
      "net.ipv4.tcp_rmem" = "4096 65536 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      "net.ipv4.tcp_congestion_control" = "bbr";

      # Enable TCP window scaling
      "net.ipv4.tcp_window_scaling" = 1;

      # Optimize for WiFi latency
      "net.ipv4.tcp_timestamps" = 1;
      "net.ipv4.tcp_sack" = 1;

      # Reduce retransmit timeout
      "net.ipv4.tcp_retries2" = 8;
    };

    # Systemd service to optimize WiFi on startup and resume
    systemd.services.wifi-performance = {
      description = "WiFi Performance Optimization";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Wait for WiFi interface to be available
        for i in {1..30}; do
          if ls /sys/class/net/w* >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        # Apply optimizations to all WiFi interfaces
        for iface in /sys/class/net/w*; do
          if [ -d "$iface" ]; then
            iface_name=$(basename "$iface")

            # Disable power saving for performance
            ${pkgs.iw}/bin/iw dev "$iface_name" set power_save off 2>/dev/null || true

            # Set regulatory domain (adjust as needed for your country)
            ${pkgs.iw}/bin/iw reg set US 2>/dev/null || true

            # Optimize interface settings
            if command -v ethtool >/dev/null 2>&1; then
              # Increase ring buffer sizes if supported
              ${pkgs.ethtool}/bin/ethtool -G "$iface_name" rx 512 tx 512 2>/dev/null || true
            fi
          fi
        done
      '';
    };

    # Resume script to re-apply optimizations after suspend
    systemd.services.wifi-performance-resume = {
      description = "WiFi Performance Optimization on Resume";
      after = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
      wantedBy = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        # Re-run optimization script after resume
        systemctl start wifi-performance.service
      '';
    };
  };
}
