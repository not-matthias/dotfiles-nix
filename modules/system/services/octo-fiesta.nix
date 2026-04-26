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
      default = "v0.8";
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
      volumes = ["${navidromeCfg.musicFolder}/octo-fiesta:/app/downloads"];
      environment = {
        Library__DownloadPath = "/app/downloads";

        Subsonic__Url = "http://host.docker.internal:${toString navidromeCfg.settings.Port}";
        Subsonic__MusicService = "SquidWTF";
        Subsonic__StorageMode = "Permanent";
        Subsonic__EnableExternalPlaylists = "true";
        Subsonic__FolderTemplate = "{artist}/{album}/{track} - {title}";

        SquidWTF__Source = "Tidal";
        SquidWTF__Quality = "HI_RES_LOSSLESS";
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
