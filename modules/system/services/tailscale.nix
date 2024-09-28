# https://tailscale.com/download/linux/nixos
{
  services.tailscale.enable = true;

  # Setup MagicDNS
  services.resolved.enable = true;
  networking.nameservers = ["100.100.100.100" "1.1.1.1"];
  networking.search = ["tail7e2f43.ts.net"];

  environment.shellAliases = {
    ts = "tailscale";
    tsu = "tailscale up";
    tsd = "tailscale down";
    tss = "tailscale status";
  };
}
