# https://tailscale.com/download/linux/nixos
{
  services.tailscale.enable = true;

  # Setup MagicDNS
  # FIXME: Doesn't work together with adguard dns (i think)
  services.resolved.enable = true;
  networking.nameservers = ["100.100.100.100"];
  networking.search = ["ide-snares.ts.net"];

  # Allow the Caddy user(and service) to edit certs
  # - https://tailscale.com/blog/caddy
  # - https://caddyserver.com/docs/automatic-https#activation
  # - https://search.nixos.org/options?show=services.tailscale.permitCertUid
  services.tailscale.permitCertUid = "caddy";

  environment.shellAliases = {
    ts = "tailscale";
    tsu = "tailscale up";
    tsd = "tailscale down";
    tss = "tailscale status";
  };
}
