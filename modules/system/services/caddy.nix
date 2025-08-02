{
  domain,
  unstable,
  config,
  ...
}: {
  # TODO: Turn into options, with tailnetName

  # TODO: https://github.com/frahz/nix-config/blob/9fefb303a64ce1f4169169597c5a1acac3b00d7e/hosts/chibi/services/caddy.nix#L30
  networking.hosts = {
    # I'm only ever going to use this on my laptop.
    "127.0.0.1" = [
      "laptop.local"
    ];
    "100.126.233" = [
      "desktop.local"
    ];
  };

  services.caddy = {
    environmentFile = config.age.secrets.duckdns.path;
    package = unstable.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/duckdns@v0.5.0"];
      hash = "sha256-YS+9pEuNaU2vN+pBHuuqZnPW/Fk5I+IQh2K99L0vPLo=";
    };

    virtualHosts."*.${domain}".extraConfig = ''
      tls {
          dns duckdns {env.DUCKDNS_TOKEN}
      }
    '';

    virtualHosts."${domain}".extraConfig = ''
      respond "Hello, world!"
    '';
    virtualHosts."${domain}/test".extraConfig = ''
      respond "Path works!"
    '';
    virtualHosts."test.${domain}".extraConfig = ''
      respond "Subdomains work!"
    '';

    # Docker services (not yet here)
    #
    virtualHosts."immich.${domain}".extraConfig = ''
      encode zstd gzip

      reverse_proxy http://127.0.0.1:2283
    '';
  };
}
