{
  config,
  lib,
  domain,
  user,
  pkgs,
  ...
}: let
  cfg = config.services.multi-scrobbler;
  desktopUid = 1000;
  desktopGid = config.ids.gids.users;
  sessionBus = "/run/user/${toString desktopUid}/bus";
  version = "0.16.5";
  # Each MPRIS poll owns one bus connection and closes it before returning.
  mprisSource =
    pkgs.runCommand "multi-scrobbler-${version}-MPRISSource.ts" {
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/foxxmd/multi-scrobbler/${version}/src/backend/sources/MPRISSource.ts";
        hash = "sha256-OBf1nx6+DzCJOMy/5feVW+hGMOAetjsBjrCnqo/h/JA=";
      };
      nativeBuildInputs = [pkgs.patch];
    } ''
      cp "$src" "$out"
      chmod u+w "$out"
      patch --fuzz=0 "$out" < ${./multi-scrobbler-mpris.patch}
    '';
in {
  options.services.multi-scrobbler.enable = lib.mkEnableOption "Enable multi-scrobbler";

  config = lib.mkIf cfg.enable {
    system.build.multi-scrobbler-mpris-source = mprisSource;

    age.secrets = {
      maloja-api-key = {
        file = ../../../secrets/maloja-api-key.age;
        owner = "root";
        group = "root";
      };
      spotify-client-id = {
        file = ../../../secrets/spotify-client-id.age;
        owner = "root";
        group = "root";
      };
      spotify-client-secret = {
        file = ../../../secrets/spotify-client-secret.age;
        owner = "root";
        group = "root";
      };
    };
    virtualisation.oci-containers.containers.multi-scrobbler = {
      # https://hub.docker.com/r/foxxmd/multi-scrobbler
      image = "foxxmd/multi-scrobbler:${version}";
      environment = {
        TZ = "Etc/GMT";
        PUID = toString desktopUid;
        PGID = toString desktopGid;
        MALOJA_ID = "myMalojaClient";
        MALOJA_URL = "http://desktop.local:42010";
        SPOTIFY_ID = "MySpotify";
        SPOTIFY_REDIRECT_URI = "http://127.0.0.1:9078/callback";
        WS_ENABLE = "true";
        WS_ID = "MyWebScrobbler";
        MPRIS_ID = "DesktopPlayers";
        MPRIS_WHITELIST = "Feishin,io.github.lullabyX.sone";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=${sessionBus}";
      };
      environmentFiles = [
        config.age.secrets.maloja-api-key.path
        config.age.secrets.spotify-client-id.path
        config.age.secrets.spotify-client-secret.path
      ];
      # Host networking shares interfaces, but Docker has its own /etc/hosts.
      extraOptions =
        ["--network=host"]
        ++ lib.concatLists (lib.mapAttrsToList
          (address: names: map (name: "--add-host=${name}:${address}") names)
          config.networking.hosts);
      volumes = [
        "/var/lib/multi-scrobbler:/config"
        "${sessionBus}:${sessionBus}:ro"
        "${mprisSource}:/app/src/backend/sources/MPRISSource.ts:ro"
      ];
    };

    # The container authenticates to the desktop user's session bus by UID.
    systemd.services.docker-multi-scrobbler = {
      requires = ["user@${toString desktopUid}.service"];
      after = ["user@${toString desktopUid}.service"];
    };

    # Feishin uses MPRIS here; Navidrome still scrobbles other clients directly.
    home-manager.users.${user}.home.sessionVariables.FS_PLAYBACK_SCROBBLE_ENABLED = "false";

    services.caddy.virtualHosts."multi-scrobbler.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:9078
    '';

    # Ensure the config directory exists with proper permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/multi-scrobbler 0755 root root -"
    ];
  };
}
