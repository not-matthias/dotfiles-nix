# https://tailscale.com/download/linux/nixos
{
  services.tailscale = {
    enable = true;
  };

  # Setup MagicDNS
  networking.nameservers = ["100.100.100.100" "1.1.1.1"];
  networking.search = ["example.ts.net"];
}
