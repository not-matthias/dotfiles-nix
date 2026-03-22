{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.octo-fiesta;
  navidromeCfg = config.services.navidrome;
  port = 5274;
in {
  options.services.octo-fiesta = {
    enable = lib.mkEnableOption "octo-fiesta Subsonic proxy";

    version = lib.mkOption {
      type = lib.types.str;
      default = "v0.7";
      description = "Docker image tag";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = navidromeCfg.enable;
        message = "octo-fiesta requires Navidrome to be enabled";
      }
    ];

    virtualisation.oci-containers.containers.octo-fiesta = {
      image = "ghcr.io/v1ck3s/octo-fiesta:${cfg.version}";
      ports = ["${toString port}:8080"];
      volumes = ["${navidromeCfg.musicFolder}:/app/downloads"];
      environment = {
        SUBSONIC_URL = "http://host.docker.internal:${toString navidromeCfg.settings.Port}";
        MUSIC_SERVICE = "SquidWTF";
        STORAGE_MODE = "Permanent";
        SQUIDWTF_SOURCE = "Qobuz";
        SQUIDWTF_QUALITY = "27";
        ENABLE_EXTERNAL_PLAYLISTS = "true";
        FOLDER_TEMPLATE = "{artist}/{album}/{track} - {title}";
      };
      extraOptions = ["--add-host=host.docker.internal:host-gateway"];
    };

    # Inherit mount dependency from Navidrome (they share the same music directory)
    systemd.services.docker-octo-fiesta = lib.mkIf (navidromeCfg.requiredMount != null) {
      requires = [navidromeCfg.requiredMount];
      after = [navidromeCfg.requiredMount];
    };

    services.caddy.virtualHosts."music-proxy.${domain}" = {
      extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:${toString port}
      '';
    };
  };
}
