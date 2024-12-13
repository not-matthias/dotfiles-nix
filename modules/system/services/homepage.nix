{domain, ...}: {
  # Find the icons here:
  # - https://github.com/walkxcode/Dashboard-Icons/tree/main/svg
  # - https://gethomepage.dev/configs/services/#icons
  services.homepage-dashboard = {
    enable = true;
    listenPort = 7676;

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
              href = "https://adguard.server.local";
              siteMonitor = "https://adguard.server.local";
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
              href = "https://ollama.desktop.local";
              siteMonitor = "https://ollama.desktop.local";
            };
          }
          {
            Miniflux = {
              description = "Miniflux";
              icon = "miniflux";
              href = "https://rss.desktop.local";
            };
          }
          {
            Scrutiny = {
              description = "S.M.A.R.T. Monitoring";
              icon = "scrutiny";
              href = "https://scrutiny.desktop.local";
              siteMonitor = "https://scrutiny.desktop.local";
            };
          }
          {
            Memos = {
              description = "Memos";
              icon = "memos";
              href = "https://memos.desktop.local";
              siteMonitor = "https://memos.desktop.local";
            };
          }
          {
            Netdata = {
              description = "Netdata";
              icon = "netdata";
              href = "https://netdata.desktop.local";
              siteMonitor = "https://netdata.desktop.local";
            };
          }
          {
            Immich = {
              description = "Immich";
              icon = "immich";
              href = "https://immich.desktop.local";
              siteMonitor = "https://immich.desktop.local";
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
