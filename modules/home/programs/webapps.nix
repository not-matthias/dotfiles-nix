{
  config,
  pkgs,
  lib,
  flakes,
  ...
}: let
  inherit ((flakes.nix-webapps.overlays.lib pkgs pkgs).nix-webapp-lib) mkFirefoxApp;
  cfg = config.programs.webapps;
in {
  options.programs.webapps = {
    twenty.enable = lib.mkEnableOption "Twenty CRM webapp";
    lobe-chat.enable = lib.mkEnableOption "Lobe Chat AI webapp";
    hackernews.enable = lib.mkEnableOption "Hacker News webapp";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.twenty.enable {
      home.packages = [
        (mkFirefoxApp {
          name = "twenty";
          url = "https://twenty.desktopnm.duckdns.org/";
          firefoxBin = lib.getExe pkgs.librewolf;

          makeDesktopItemArgs = {
            comment = "Customer Relationship Management";
            icon = "folder-remote";
            genericName = "CRM";
            categories = [
              "Office"
              "Network"
            ];
          };
        })
      ];
    })

    (lib.mkIf cfg.lobe-chat.enable {
      home.packages = [
        (mkFirefoxApp {
          name = "lobe-chat";
          url = "https://lobe-chat.desktopnm.duckdns.org/";
          firefoxBin = lib.getExe pkgs.librewolf;

          makeDesktopItemArgs = {
            comment = "AI Chat Interface";
            icon = "application-chat";
            genericName = "AI Chat";
            categories = [
              "Network"
              "Utility"
            ];
          };
        })
      ];
    })

    (lib.mkIf cfg.hackernews.enable {
      home.packages = [
        (mkFirefoxApp {
          name = "hackernews";
          url = "https://news.ycombinator.com/";
          firefoxBin = lib.getExe pkgs.librewolf;

          makeDesktopItemArgs = {
            comment = "Hacker News - Technology and startup news";
            icon = "internet-news-reader";
            genericName = "News Reader";
            categories = [
              "Network"
              "News"
            ];
          };
        })
      ];
    })
  ];
}
