{domain, ...}: let
  desktopDomain = "desktopnm.duckdns.org";
in {
  # Find the icons here:
  # - https://github.com/walkxcode/Dashboard-Icons/tree/main/svg
  # - https://gethomepage.dev/configs/services/#icons
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
        "Services" = [
          {
            "AdGuard Home" = {
              description = "AdGuard Home";
              icon = "adguard-home";
              href = "https://adguard.${desktopDomain}";
              siteMonitor = "https://adguard.${desktopDomain}";
            };
          }
          {
            "OpenWebUI (laptop)" = {
              description = "OpenWebUI";
              icon = "ollama";
              href = "https://ollama.laptop.local";
              siteMonitor = "https://ollama.laptop.local";
            };
          }
          {
            "OpenWebUI (server)" = {
              description = "OpenWebUI";
              icon = "ollama";
              href = "https://ollama.${desktopDomain}";
              siteMonitor = "https://ollama.${desktopDomain}";
            };
          }
          {
            Miniflux = {
              description = "Miniflux";
              icon = "miniflux";
              href = "https://rss.${desktopDomain}";
              siteMonitor = "https://rss.${desktopDomain}";
            };
          }
          {
            Scrutiny = {
              description = "S.M.A.R.T. Monitoring";
              icon = "scrutiny";
              href = "https://scrutiny.${desktopDomain}";
              siteMonitor = "https://scrutiny.${desktopDomain}";
            };
          }
          {
            Memos = {
              description = "Memos";
              icon = "memos";
              href = "https://memos.${desktopDomain}";
              siteMonitor = "https://memos.${desktopDomain}";
            };
          }
          {
            Netdata = {
              description = "Netdata";
              icon = "netdata";
              href = "https://netdata.${desktopDomain}";
              siteMonitor = "https://netdata.${desktopDomain}";
            };
          }
          {
            Immich = {
              description = "Immich";
              icon = "immich";
              href = "https://immich.${desktopDomain}";
              siteMonitor = "https://immich.${desktopDomain}";
            };
          }
          {
            Paperless = {
              description = "Paperless";
              icon = "paperless";
              href = "https://paperless.${desktopDomain}";
              siteMonitor = "https://paperless.${desktopDomain}";
            };
          }
          {
            Gitea = {
              description = "Gitea";
              icon = "gitea";
              href = "https://git.${desktopDomain}";
              siteMonitor = "https://git.${desktopDomain}";
            };
          }
          {
            Stump = {
              description = "Stump";
              icon = "stump";
              href = "https://books.${desktopDomain}";
              siteMonitor = "https://books.${desktopDomain}";
            };
          }
          {
            Maloja = {
              description = "Maloja";
              icon = "maloja";
              href = "https://maloja.${desktopDomain}";
              siteMonitor = "https://maloja.${desktopDomain}";
            };
          }
          {
            Audiobookshelf = {
              description = "Audiobookshelf";
              icon = "audiobookshelf";
              href = "https://audiobooks.${desktopDomain}";
              siteMonitor = "https://audiobooks.${desktopDomain}";
            };
          }
          {
            Jellyfin = {
              description = "Jellyfin";
              icon = "jellyfin";
              href = "https://jellyfin.${desktopDomain}";
              siteMonitor = "https://jellyfin.${desktopDomain}";
            };
          }
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
}
