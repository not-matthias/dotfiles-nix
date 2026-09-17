{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.choosr;
  chromiumWorkDesktop = "chromium-work.desktop";
  choosrDesktop = "choosr.desktop";
  httpMime = "x-scheme-handler/http";
  httpsMime = "x-scheme-handler/https";
in {
  options.programs.choosr.enable = mkEnableOption "Choosr browser routing";

  config = mkIf cfg.enable {
    home.packages = [pkgs.choosr];

    xdg.configFile = {
      "choosr/rules.toml".text = ''
        [[rule]]
        name = "Work GitHub"
        condition_type = "regexp"
        value = "(?i)^github\\.com/(codspeedhq|avalanchehq)(?:/|$)"
        action_type = "open_browser"
        browser = "Chromium Work"
        enabled = true

        [[rule]]
        name = "Default"
        action_type = "open_browser"
        browser = "Helium"
        enabled = true
        is_default = true
      '';
      "choosr/config.toml".text = ''
        [default_browser]
        enabled = true
        browser = "Helium"
      '';
    };

    xdg.desktopEntries = {
      chromium-work = {
        name = "Chromium Work";
        exec = "${pkgs.chromium}/bin/chromium --user-data-dir=${config.xdg.dataHome}/chromium-work %U";
        type = "Application";
        terminal = false;
        mimeType = [
          httpMime
          httpsMime
        ];
      };
      choosr = {
        name = "choosr";
        exec = "${pkgs.choosr}/bin/choosr %u";
        type = "Application";
        terminal = false;
        noDisplay = true;
        mimeType = [
          httpMime
          httpsMime
        ];
      };
    };

    xdg.mimeApps = {
      enable = true;
      associations.added = {
        ${httpMime} = [
          chromiumWorkDesktop
          choosrDesktop
        ];
        ${httpsMime} = [
          chromiumWorkDesktop
          choosrDesktop
        ];
      };
      defaultApplications = {
        ${httpMime} = choosrDesktop;
        ${httpsMime} = choosrDesktop;
      };
    };
  };
}
