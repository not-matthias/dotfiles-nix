{
  domain,
  unstable,
  lib,
  config,
  ...
}: let
  cfg = config.services.tandoor-recipes;
in {
  config = lib.mkIf cfg.enable {
    services.tandoor-recipes = {
      package = unstable.tandoor-recipes;
      port = 11423;
    };

    services.caddy.virtualHosts."recipes.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://localhost:11423
    '';

    services.restic.paths = ["/var/lib/tandoor-recipes"];
  };
}
