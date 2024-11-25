{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: let
  cfg = config.services.firefly-iii;
in {
  config = lib.mkIf cfg.enable {
    services.firefly-iii = {
      package = unstable.firefly-iii;
      # TODO: Set dataDir
      settings = {
        # TODO: Setup secret mgmt system, but for now this is fine since it's not publicly accessible
        # Generate with: openssl rand -base64 32
        APP_KEY_FILE = pkgs.writeText "APP_KEY" ''base64:zT119/59AOR/f2dF4OgxdZbytoit3mbBKEjZ9egk6Nk='';
      };
      enableNginx = true;
      virtualHost = "firefly";
    };
  };
}
