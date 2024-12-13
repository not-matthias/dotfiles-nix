{domain, ...}: {
  networking.hosts = {
    "100.121.111.38" = [
      "laptop.local"
      "test.laptop.local"
    ];
    "100.64.120.57" = [
      "desktop.local"
      "test.desktop.local"
      "memos.desktop.local"
      "ollama.desktop.local"
    ];
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      auto_https disable_redirects
    '';
    virtualHosts."${domain}".extraConfig = ''
      respond "Hello, world!"
    '';
    virtualHosts."test.${domain}".extraConfig = ''
      respond "Subdomains work!"
    '';
  };
}
