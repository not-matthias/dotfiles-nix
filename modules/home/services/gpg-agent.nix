{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.services.gpg-agent;
in {
  config = lib.mkIf cfg.enable {
    programs.gpg.enable = true;
    services.gpg-agent = {
      enableSshSupport = true;
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-qt;
    };
  };
}
