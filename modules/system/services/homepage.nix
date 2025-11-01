{
  domain,
  config,
  lib,
  ...
}: let
  cfg = config.services.homepage-dashboard;

  # Helper function to conditionally include a service
  includeService = serviceName: serviceConfig:
    lib.optionals (config.services.${serviceName}.enable or false) [serviceConfig];
in {
  # Find the icons here:
  # - https://github.com/walkxcode/Dashboard-Icons/tree/main/svg
  # - https://gethomepage.dev/configs/services/#icons

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      listenPort = 7676;
      allowedHosts = "*";

      settings = {
        title = "Homepage";
        headerStyle = "clean";
        statusStyle = "dot";
        cardBlur = "sm";
        language = "en";
        hideVersion = true;
        showStats = true;
        fiveColumns = true;

        layout = [
          {
            "Services" = {
              style = "row";
              columns = 4;
              header = false;
            };
          }
        ];
      };

      services = [
        {
          "Services" = lib.flatten [
            (includeService "adguardhome" {
              "AdGuard Home" = {
                description = "AdGuard Home";
                icon = "adguard-home";
                href = "https://adguard.${domain}";
                siteMonitor = "https://adguard.${domain}";
              };
            })
            (includeService "open-webui" {
              "OpenWebUI (server)" = {
                description = "OpenWebUI";
                icon = "ollama";
                href = "https://ollama.${domain}";
                siteMonitor = "https://ollama.${domain}";
              };
            })
            (includeService "miniflux" {
              Miniflux = {
                description = "Miniflux";
                icon = "miniflux";
                href = "https://rss.${domain}";
                siteMonitor = "https://rss.${domain}";
              };
            })
            (includeService "scrutiny" {
              Scrutiny = {
                description = "S.M.A.R.T. Monitoring";
                icon = "scrutiny";
                href = "https://scrutiny.${domain}";
                siteMonitor = "https://scrutiny.${domain}";
              };
            })
            (includeService "memos" {
              Memos = {
                description = "Memos";
                icon = "memos";
                href = "https://memos.${domain}";
                siteMonitor = "https://memos.${domain}";
              };
            })
            (includeService "netdata" {
              Netdata = {
                description = "Netdata";
                icon = "netdata";
                href = "https://netdata.${domain}";
                siteMonitor = "https://netdata.${domain}";
              };
            })
            (includeService "immich" {
              Immich = {
                description = "Immich";
                icon = "immich";
                href = "https://immich.${domain}";
                siteMonitor = "https://immich.${domain}";
              };
            })
            (includeService "paperless" {
              Paperless = {
                description = "Paperless";
                icon = "paperless";
                href = "https://paperless.${domain}";
                siteMonitor = "https://paperless.${domain}";
              };
            })
            (includeService "gitea" {
              Gitea = {
                description = "Gitea";
                icon = "gitea";
                href = "https://git.${domain}";
                siteMonitor = "https://git.${domain}";
              };
            })
            (includeService "stump" {
              Stump = {
                description = "Stump";
                icon = "stump";
                href = "https://books.${domain}";
                siteMonitor = "https://books.${domain}";
              };
            })
            (includeService "maloja" {
              Maloja = {
                description = "Maloja";
                icon = "maloja";
                href = "https://maloja.${domain}";
                siteMonitor = "https://maloja.${domain}";
              };
            })
            (includeService "audiobookshelf" {
              Audiobookshelf = {
                description = "Audiobookshelf";
                icon = "audiobookshelf";
                href = "https://audiobooks.${domain}";
                siteMonitor = "https://audiobooks.${domain}";
              };
            })
            (includeService "jellyfin" {
              Jellyfin = {
                description = "Jellyfin";
                icon = "jellyfin";
                href = "https://jellyfin.${domain}";
                siteMonitor = "https://jellyfin.${domain}";
              };
            })
            (includeService "karakeep" {
              Karakeep = {
                description = "Karakeep";
                icon = "karakeep";
                href = "https://links.${domain}";
                siteMonitor = "https://links.${domain}";
              };
            })
            (includeService "n8n" {
              n8n = {
                description = "n8n";
                icon = "n8n";
                href = "https://n8n.${domain}";
                siteMonitor = "https://n8n.${domain}";
              };
            })
            (includeService "nocodb" {
              NocoDB = {
                description = "NocoDB";
                icon = "nocodb";
                href = "https://nocodb.${domain}";
                siteMonitor = "https://nocodb.${domain}";
              };
            })
            (includeService "solidtime" {
              Solidtime = {
                description = "Solidtime";
                icon = "solidtime";
                href = "https://solidtime.${domain}";
                siteMonitor = "https://solidtime.${domain}";
              };
            })
            (includeService "lobe-chat" {
              "Lobe Chat" = {
                description = "Lobe Chat";
                icon = "lobe-chat";
                href = "https://chat.${domain}";
                siteMonitor = "https://chat.${domain}";
              };
            })
            (includeService "navidrome" {
              Navidrome = {
                description = "Navidrome";
                icon = "navidrome";
                href = "https://music.${domain}";
                siteMonitor = "https://music.${domain}";
              };
            })
            (includeService "twenty" {
              Twenty = {
                description = "Twenty";
                icon = "twenty";
                href = "https://twenty.${domain}";
                siteMonitor = "https://twenty.${domain}";
              };
            })
            (includeService "sure" {
              Sure = {
                description = "Sure";
                icon = "sure";
                href = "https://sure.${domain}";
                siteMonitor = "https://sure.${domain}";
              };
            })
            (includeService "wakapi" {
              Wakapi = {
                description = "Wakapi";
                icon = "wakatime";
                href = "https://wakapi.${domain}";
                siteMonitor = "https://wakapi.${domain}";
              };
            })
            (includeService "librechat" {
              LibreChat = {
                description = "LibreChat";
                icon = "librechat";
                href = "https://librechat.${domain}";
                siteMonitor = "https://librechat.${domain}";
              };
            })
            (includeService "multi-scrobbler" {
              "Multi Scrobbler" = {
                description = "Multi Scrobbler";
                icon = "multi-scrobbler";
                href = "https://scrobbler.${domain}";
                siteMonitor = "https://scrobbler.${domain}";
              };
            })
            (includeService "slskd" {
              Slskd = {
                description = "Slskd";
                icon = "slskd";
                href = "https://slskd.${domain}";
                siteMonitor = "https://slskd.${domain}";
              };
            })
            (includeService "ziit" {
              Ziit = {
                description = "Ziit";
                icon = "ziit";
                href = "https://ziit.${domain}";
                siteMonitor = "https://ziit.${domain}";
              };
            })
            (includeService "redlib" {
              Redlib = {
                description = "Redlib";
                icon = "reddit";
                href = "https://redlib.${domain}";
                siteMonitor = "https://redlib.${domain}";
              };
            })
            (includeService "postiz" {
              Postiz = {
                description = "Postiz";
                icon = "postiz";
                href = "https://postiz.${domain}";
                siteMonitor = "https://postiz.${domain}";
              };
            })
            (includeService "calibre-web" {
              "Calibre Web" = {
                description = "Calibre Web";
                icon = "calibre-web";
                href = "https://calibre.${domain}";
                siteMonitor = "https://calibre.${domain}";
              };
            })
            (includeService "dawarich" {
              Dawarich = {
                description = "Dawarich";
                icon = "dawarich";
                href = "https://dawarich.${domain}";
                siteMonitor = "https://dawarich.${domain}";
              };
            })
          ];
        }
      ];

      widgets = [
        {
          greeting = {
            text_size = "xl";
            text = "Homepage";
          };
        }
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
          };
        }
        {
          datetime = {
            text_size = "xl";
            format = {
              dateStyle = "short";
              timeStyle = "short";
              hour12 = true;
            };
          };
        }
      ];
    };

    services.caddy.virtualHosts."home.${domain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:7676
    '';
  };
}
