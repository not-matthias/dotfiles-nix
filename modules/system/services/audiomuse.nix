{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.services.audiomuse;
in {
  options.services.audiomuse = {
    enable = lib.mkEnableOption "AudioMuse AI with Navidrome plugin";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      home.packages = [
        pkgs.audiomuse-ai
        pkgs.audiomuse-ai-nv-plugin
      ];
    };

    systemd.tmpfiles.settings.navidromePlugins."/var/lib/navidrome/plugins"."d" = {
      mode = "0755";
      user = "navidrome";
      group = "navidrome";
    };

    systemd.services.navidrome.preStart = lib.mkAfter ''
      install -Dm444 \
        ${pkgs.audiomuse-ai-nv-plugin}/share/navidrome-plugins/audiomuseai.ndp \
        /var/lib/navidrome/plugins/audiomuseai.ndp
    '';
  };
}
