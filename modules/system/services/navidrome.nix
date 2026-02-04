{
  config,
  lib,
  unstable,
  domain,
  ...
}: let
  cfg = config.services.navidrome;
in {
  options.services.navidrome = {
    musicFolder = lib.mkOption {
      type = lib.types.str;
      description = "The path to the music folder (must be the real path, not a bind mount target)";
    };

    # Requires /1/ at the end!
    # IMPORTANT: This requires manual interaction to enable scrobbling
    # in the UI. Login, then click on "Personal", then "Scrobble to ListenBrainz" and
    # paste the Maloja API token.
    scrobblerUrl = lib.mkOption {
      type = lib.types.str;
      description = "The URL to the ListenBrainz API";
    };

    requiredMount = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "mnt-data-personal.mount";
      description = "Systemd mount unit that must be available before Navidrome starts";
    };
  };

  config = lib.mkIf cfg.enable {
    services.navidrome = {
      package = unstable.navidrome;
      settings = {
        Port = 11424;
        Address = "0.0.0.0";
        MusicFolder = cfg.musicFolder;

        ListenBrainz.BaseURL = cfg.scrobblerUrl;
        ListenBrainz.Enabled = cfg.scrobblerUrl != "";
      };
    };

    # Ensure Navidrome only starts after the music folder mount is available.
    # This prevents the previous issue where a bind mount would resolve to an
    # empty directory if /mnt/data/personal wasn't mounted yet.
    systemd.services.navidrome = lib.mkIf (cfg.requiredMount != null) {
      requires = [cfg.requiredMount];
      after = [cfg.requiredMount];
      serviceConfig.RequiresMountsFor = [cfg.musicFolder];
    };

    services.caddy.virtualHosts."music.${domain}" = {
      extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:11424
      '';
    };

    services.restic.paths = ["/var/lib/navidrome"];
    services.restic.excludes = [
      "/var/lib/navidrome/cache"
    ];
  };
}
