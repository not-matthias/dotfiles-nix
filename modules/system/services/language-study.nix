{
  config,
  domain,
  flakes,
  lib,
  ...
}: {
  imports = [flakes.language-study.nixosModules.default];

  options.services.language-study.enable = lib.mkEnableOption "German and Chinese study services";

  config = lib.mkIf config.services.language-study.enable {
    age.secrets.language-study-env.file = ../../../secrets/language-study-env.age;

    # Provision root-owned, mode 0644 Flashgen databases here before activation.
    # Content is read-only; learner progress lives in each service's dataDir.
    systemd.tmpfiles.rules = ["d /var/lib/study-content 0755 root root -"];

    services = {
      german-study = {
        enable = true;
        contentDb = "/var/lib/study-content/german.db";
        environmentFile = config.age.secrets.language-study-env.path;
        host = "127.0.0.1";
        port = 3010;
        origin = "https://de.${domain}";
      };
      chinese-study = {
        enable = true;
        contentDb = "/var/lib/study-content/sinostack.db";
        environmentFile = config.age.secrets.language-study-env.path;
        host = "127.0.0.1";
        port = 3011;
        origin = "https://zh.${domain}";
      };
      caddy.virtualHosts."de.${domain}".extraConfig = ''
        reverse_proxy http://127.0.0.1:3010
      '';
      caddy.virtualHosts."zh.${domain}".extraConfig = ''
        reverse_proxy http://127.0.0.1:3011
      '';
      restic = {
        paths = [
          config.services.german-study.dataDir
          config.services.chinese-study.dataDir
        ];
        # Generated speech can be rebuilt from content; only learner progress needs backup.
        excludes = [
          config.services.german-study.audioCacheDir
          config.services.chinese-study.audioCacheDir
        ];
      };
    };
  };
}
