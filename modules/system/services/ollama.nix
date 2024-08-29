{
  pkgs,
  config,
  ...
}: let
  unstable =
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      sha256 = "sha256:0g0m7zhpnbgzwn4gmqhjvqd9v6d917p1dg3fk1kwxs2x7v7c1zd4";
    }) {
      system = "x86_64-linux";

      config = {
        allowUnfree = true;
      };
    };
  # unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in {
  environment.systemPackages = with pkgs; [
    unstable.ollama
  ];

  networking.firewall.allowedTCPPorts = [
    #config.services.ollama.port
    config.services.open-webui.port
  ];

  services.ollama = {
    enable = true;
    package = unstable.ollama;
    #host = "0.0.0.0";
    #port = 11434;
    acceleration = "cuda";
  };

  services.open-webui = {
    enable = true;
    package = unstable.open-webui;
    host = "0.0.0.0";
    port = 11435;
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";

      # SCARF_NO_ANALYTICS = "True";
      # DO_NOT_TRACK = "True";
      # ANONYMIZED_TELEMETRY = "False";

      #ENABLE_COMMUNITY_SHARING = "False";
      #ENABLE_ADMIN_EXPORT = "False";

      #WEBUI_AUTH = "False";
      #ENABLE_SIGNUP = "False";
      #WEBUI_AUTH_TRUSTED_EMAIL_HEADER = "X-Email";
      #DEFAULT_USER_ROLE = "user";
    };
  };
}