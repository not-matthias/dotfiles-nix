{...}: {
  # networking.nat.enable = true;
  # networking.nat.externalInterface = "eth0";
  # networking.nat.internalInterfaces = ["wg0"];
  # networking.firewall = {
  #   allowedUDPPorts = [51820];
  # };

  # https://cs.github.com/welteki/serokell.nix/blob/46d762e5107d10ad409295a7f668939c21cc048d/modules/wireguard-monitoring.nix
  # https://cs.github.com/ali-abrar/nix-files/blob/642c1bfe5cbfa0b5289eae174db365bad2ae40e0/modules/vpn/client.nix?q=%22networking.wireguard.interfaces%22++language%3Anix
  # https://cs.github.com/bkchr/nixos-config/blob/c558b1b940c38091eb95d2d7c6b7e2246662bab5/system-with-gui-configuration.nix?q=%22networking.wireguard.interfaces%22++language%3Anix#L157-L176
  # https://cs.github.com/winpat/dotfiles/blob/7a56a66850791bf83543a999f597eb0fed158ce1/nixos/gem-configuration.nix?q=%22networking.wireguard.interfaces%22++language%3Anix#L37-L53
  # https://cs.github.com/cchalc/notusknot-dotfiles-nix/blob/2a16781bc2e12119eab2f2636fa69a862d25a6f8/config/hosts/vps.nix?q=%22networking.wireguard.interfaces%22++language%3Anix#L44-L67
  # https://cs.github.com/leo60228/dotfiles/blob/a02b778f04c33480b703c8d8e04daa89ed40ee87/systems/leoservices.nix?q=%22networking.wireguard.interfaces%22++language%3Anix#L98-L110
  networking.wireguard.interfaces = {
    wg0 = {
      ips = ["10.100.0.1/24"];
      listenPort = 51820;

      #   # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      #   # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      #   postSetup = ''
      #     ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      #   '';

      #   # This undoes the above command
      #   postShutdown = ''
      #     ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      #   '';

      privateKeyFile = "/etc/test.key";
      peers = [
        # {
        #   publicKey = "{client public key}";
        #   allowedIPs = ["10.100.0.2/32"];
        # }
      ];
    };
  };
}
