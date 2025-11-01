{
  domain,
  config,
  lib,
  ...
}: let
  desktopDomain = "desktopnm.duckdns.org";
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
                href = "https://adguard.${desktopDomain}";
                siteMonitor = "https://adguard.${desktopDomain}";
              };
            })
            (includeService "open-webui" {
              "OpenWebUI (server)" = {
                description = "OpenWebUI";
                icon = "ollama";
                href = "https://ollama.${desktopDomain}";
                siteMonitor = "https://ollama.${desktopDomain}";
              };
            })
            (includeService "miniflux" {
              Miniflux = {
                description = "Miniflux";
                icon = "miniflux";
                href = "https://rss.${desktopDomain}";
                siteMonitor = "https://rss.${desktopDomain}";
              };
            })
            (includeService "scrutiny" {
              Scrutiny = {
                description = "S.M.A.R.T. Monitoring";
                icon = "scrutiny";
                href = "https://scrutiny.${desktopDomain}";
                siteMonitor = "https://scrutiny.${desktopDomain}";
              };
            })
            (includeService "memos" {
              Memos = {
                description = "Memos";
                icon = "memos";
                href = "https://memos.${desktopDomain}";
                siteMonitor = "https://memos.${desktopDomain}";
              };
            })
            (includeService "netdata" {
              Netdata = {
                description = "Netdata";
                icon = "netdata";
                href = "https://netdata.${desktopDomain}";
                siteMonitor = "https://netdata.${desktopDomain}";
              };
            })
            (includeService "immich" {
              Immich = {
                description = "Immich";
                icon = "immich";
                href = "https://immich.${desktopDomain}";
                siteMonitor = "https://immich.${desktopDomain}";
              };
            })
            (includeService "paperless" {
              Paperless = {
                description = "Paperless";
                icon = "paperless";
                href = "https://paperless.${desktopDomain}";
                siteMonitor = "https://paperless.${desktopDomain}";
              };
            })
            (includeService "gitea" {
              Gitea = {
                description = "Gitea";
                icon = "gitea";
                href = "https://git.${desktopDomain}";
                siteMonitor = "https://git.${desktopDomain}";
              };
            })
            (includeService "stump" {
              Stump = {
                description = "Stump";
                icon = "stump";
                href = "https://books.${desktopDomain}";
                siteMonitor = "https://books.${desktopDomain}";
              };
            })
            (includeService "maloja" {
              Maloja = {
                description = "Maloja";
                icon = "maloja";
                href = "https://maloja.${desktopDomain}";
                siteMonitor = "https://maloja.${desktopDomain}";
              };
            })
            (includeService "audiobookshelf" {
              Audiobookshelf = {
                description = "Audiobookshelf";
                icon = "audiobookshelf";
                href = "https://audiobooks.${desktopDomain}";
                siteMonitor = "https://audiobooks.${desktopDomain}";
              };
            })
            (includeService "jellyfin" {
              Jellyfin = {
                description = "Jellyfin";
                icon = "jellyfin";
                href = "https://jellyfin.${desktopDomain}";
                siteMonitor = "https://jellyfin.${desktopDomain}";
              };
            })
            (includeService "karakeep" {
              Karakeep = {
                description = "Karakeep";
                icon = "karakeep";
                href = "https://links.${desktopDomain}";
                siteMonitor = "https://links.${desktopDomain}";
              };
            })
            (includeService "n8n" {
              n8n = {
                description = "n8n";
                icon = "n8n";
                href = "https://n8n.${desktopDomain}";
                siteMonitor = "https://n8n.${desktopDomain}";
              };
            })
            (includeService "nocodb" {
              NocoDB = {
                description = "NocoDB";
                icon = "nocodb";
                href = "https://nocodb.${desktopDomain}";
                siteMonitor = "https://nocodb.${desktopDomain}";
              };
            })
            (includeService "solidtime" {
              Solidtime = {
                description = "Solidtime";
                icon = "solidtime";
                href = "https://solidtime.${desktopDomain}";
                siteMonitor = "https://solidtime.${desktopDomain}";
              };
            })
            (includeService "lobe-chat" {
              "Lobe Chat" = {
                description = "Lobe Chat";
                icon = "lobe-chat";
                href = "https://chat.${desktopDomain}";
                siteMonitor = "https://chat.${desktopDomain}";
              };
            })
            (includeService "navidrome" {
              Navidrome = {
                description = "Navidrome";
                icon = "navidrome";
                href = "https://music.${desktopDomain}";
                siteMonitor = "https://music.${desktopDomain}";
              };
            })
            (includeService "twenty" {
              Twenty = {
                description = "Twenty";
                icon = "twenty";
                href = "https://crm.${desktopDomain}";
                siteMonitor = "https://crm.${desktopDomain}";
              };
            })
            (includeService "sure" {
              Sure = {
                description = "Sure";
                icon = "sure";
                href = "https://sure.${desktopDomain}";
                siteMonitor = "https://sure.${desktopDomain}";
              };
            })
            (includeService "wakapi" {
              Wakapi = {
                description = "Wakapi";
                icon = "wakatime";
                href = "https://wakapi.${desktopDomain}";
                siteMonitor = "https://wakapi.${desktopDomain}";
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
