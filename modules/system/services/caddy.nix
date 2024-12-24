{domain, ...}: {
  # TODO: https://github.com/frahz/nix-config/blob/9fefb303a64ce1f4169169597c5a1acac3b00d7e/hosts/chibi/services/caddy.nix#L30
  networking.hosts = {
    # I'm only ever going to use this on my laptop.
    "127.0.0.1" = [
      "laptop.local"
      "test.laptop.local"

      "home.laptop.local"
      "ollama.laptop.local"
      "memos.laptop.local"
      "music.laptop.local"
      "scrutiny.laptop.local"
      "lan.laptop.local"

      # Custom only for laptop:
      "music.local"
    ];
    "100.64.120.57" = [
      "desktop.local"
      "test.desktop.local"

      "home.desktop.local"
      "ollama.desktop.local"
      "memos.desktop.local"
      "music.desktop.local"
      "scrutiny.desktop.local"
      "netdata.desktop.local"
      "lan.desktop.local"

      # Server-only:
      "immich.desktop.local"
      "rss.desktop.local"
      "adguard.desktop.local"
      "paperless.desktop.local"
      "git.desktop.local"
    ];
  };

  services.caddy = {
    globalConfig = ''
      auto_https disable_redirects
    '';
    virtualHosts."${domain}".extraConfig = ''
      respond "Hello, world!"
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
