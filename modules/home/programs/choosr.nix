{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.choosr;
  googleChromeWorkDesktop = "google-chrome-work.desktop";
  choosrDesktop = "choosr.desktop";
  httpMime = "x-scheme-handler/http";
  httpsMime = "x-scheme-handler/https";
in {
  options.programs.choosr.enable = mkEnableOption "Choosr browser routing";

  config = mkIf cfg.enable {
    home.sessionVariables.BROWSER = "choosr";
    home.packages = [pkgs.choosr];

    xdg.configFile = {
      "choosr/rules.toml".text = ''
        [[rule]]
        name = "Work GitHub"
        condition_type = "regexp"
        value = "(?i)^github\\.com/(codspeedhq|avalanchehq)(?:/|$)"
        action_type = "open_browser"
        browser = "Google Chrome Work"
        enabled = true

        [[rule]]
        name = "Greptile"
        condition_type = "regexp"
        value = "(?i)^(?:[^/]+\\.)?greptile\\.com(?:[/:?#]|$)"
        action_type = "open_browser"
        browser = "Google Chrome Work"
        enabled = true

        [[rule]]
        name = "Slack"
        condition_type = "regexp"
        value = "(?i)^(?:[^/]+\\.)?slack\\.com(?:[/:?#]|$)"
        action_type = "open_browser"
        browser = "Google Chrome Work"
        enabled = true

        [[rule]]
        name = "Linear"
        condition_type = "regexp"
        value = "(?i)^(?:[^/]+\\.)?linear\\.app(?:[/:?#]|$)"
        action_type = "open_browser"
        browser = "Google Chrome Work"
        enabled = true

        [[rule]]
        name = "Notion"
        condition_type = "regexp"
        value = "(?i)^(?:[^/]+\\.)?notion\\.com(?:[/:?#]|$)"
        action_type = "open_browser"
        browser = "Google Chrome Work"
        enabled = true

        [[rule]]
        name = "Google Workspace"
        condition_type = "regexp"
        value = "(?i)^(?:mail|calendar|meet|drive|docs|sheets|slides)\\.google\\.com(?:[/:?#]|$)"
        action_type = "open_browser"
        browser = "Google Chrome Work"
        enabled = true

        [[rule]]
        name = "Chromatic"
        condition_type = "regexp"
        value = "(?i)^(?:[^/]+\\.)?chromatic\\.com(?:[/:?#]|$)"
        action_type = "open_browser"
        browser = "Google Chrome Work"
        enabled = true

        [[rule]]
        name = "Claude"
        condition_type = "regexp"
        value = "(?i)^(?:[^/]+\\.)?claude\\.ai(?:[/:?#]|$)"
        action_type = "open_browser"
        browser = "Google Chrome Work"
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
      google-chrome-work = {
        name = "Google Chrome Work";
        exec = "${pkgs.google-chrome}/bin/google-chrome-stable --profile-directory=\"Profile 1\" %U";
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
          googleChromeWorkDesktop
          choosrDesktop
        ];
        ${httpsMime} = [
          googleChromeWorkDesktop
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
