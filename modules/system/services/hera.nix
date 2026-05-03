{
  lib,
  config,
  pkgs,
  flakes,
  ...
}: let
  cfg = config.services.hera;

  # Hardcoded RPC secret (TODO: migrate to agenix). Lands in /nix/store.
  garageEnvFile = pkgs.writeText "hera-garage.env" ''
    GARAGE_RPC_SECRET=1763d831432682ec3d90af1498fe8f33d6b7f343f248e27984448b1584baa621
  '';

  # S3 credentials are minted by hera-garage-bootstrap.service every boot.
  s3CredentialsFile = "/var/lib/hera-secrets/s3.env";
in {
  imports = [flakes.hera.nixosModules.default];

  options.services.hera = {
    enable = lib.mkEnableOption "Hera platform (scraper + website + Garage S3 + Postgres)";

    publicEndpoint = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:3900";
      description = "Browser-reachable S3 endpoint used to sign download URLs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hera = {
      enable = true;
      logLevel = "info";
      website.listenAddr = "127.0.0.1:4829";
      s3 = {
        publicEndpoint = cfg.publicEndpoint;
        credentialsFile = s3CredentialsFile;
      };
    };

    services.garage = {
      enable = true;
      package = pkgs.garage_2;
      environmentFile = "${garageEnvFile}";
      settings = {
        replication_factor = 1;
        rpc_bind_addr = "127.0.0.1:3901";
        s3_api = {
          s3_region = "garage";
          api_bind_addr = "127.0.0.1:3900";
        };
        admin.api_bind_addr = "127.0.0.1:3903";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/hera-secrets 0700 root root -"
    ];

    # Idempotent every-boot bootstrap via the garage CLI (RPC). Runs after
    # garage.service is started.
    systemd.services =
      {
        hera-garage-bootstrap = {
          description = "Bootstrap Garage cluster + bucket + S3 key for Hera";
          after = ["garage.service"];
          requires = ["garage.service"];
          wantedBy = ["multi-user.target"];
          path = [
            pkgs.garage_2
            pkgs.coreutils
            pkgs.gawk
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            EnvironmentFile = "${garageEnvFile}";
          };
          script = ''
            set -euo pipefail

            # Wait up to 30s for the daemon to register RPC handlers. `status`
            # answers before they're all ready, so probe with `layout show`.
            for _ in $(seq 1 30); do
              garage layout show >/dev/null 2>&1 && break
              sleep 1
            done
            garage layout show >/dev/null

            # Capture stdout before piping (garage <2.0 panics on SIGPIPE
            # when awk exits early; harmless on 2.x).
            layout=$(garage layout show 2>/dev/null || true)
            if ! echo "$layout" | grep -qE '^[0-9a-f]{16}.*[0-9]+G'; then
              node_id=$(garage status | awk '/^[0-9a-f]{16}/ { print $1; exit }')
              garage layout assign -z dc1 -c 10G "$node_id"
              layout=$(garage layout show)
              ver=$(echo "$layout" | awk '/version/ { print $NF; exit }')
              garage layout apply --version "$((ver + 1))"
            fi

            garage bucket info hera >/dev/null 2>&1 || garage bucket create hera
            garage key info hera-key >/dev/null 2>&1 || garage key create hera-key
            garage bucket allow --read --write --owner hera --key hera-key

            info=$(garage key info hera-key --show-secret)
            ak=$(echo "$info" | awk -F': *' '/^Key ID/ { print $2; exit }')
            sk=$(echo "$info" | awk -F': *' '/^Secret key/ { print $2; exit }')

            umask 077
            printf 'S3_ACCESS_KEY=%s\nS3_SECRET_KEY=%s\n' "$ak" "$sk" \
              > ${s3CredentialsFile}
            chmod 0400 ${s3CredentialsFile}
          '';
        };
      }
      # Block hera consumers until the bootstrap has produced credentials.
      // lib.genAttrs ["hera-website" "hera-scraper"] (_: {
        after = ["hera-garage-bootstrap.service"];
        requires = ["hera-garage-bootstrap.service"];
      });
  };
}
