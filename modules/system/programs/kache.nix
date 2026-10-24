{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.kache;
  configFile = (pkgs.formats.toml {}).generate "kache-config.toml" {
    cache = {
      local_max_size = "100GB";
      cache_executables = true;
      adaptive_incremental = true;

      # Target cleanup is managed by cargo-maintenance.
      auto_clean_orphaned_targets = false;
      auto_clean_unused_units_days = 0;
    };
  };
in {
  options.programs.kache.enable = lib.mkEnableOption "Kache compiler caching";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.kache];
    environment.variables = {
      RUSTC_WRAPPER = lib.getExe pkgs.kache;
      KACHE_CONFIG = "${configFile}";
      # Build scripts can depend on undeclared system libraries and tools.
      KACHE_BUILD_SCRIPT_CACHE = "0";
    };

    systemd.user.services.kache = {
      description = "Kache build cache daemon";
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.kache} daemon run";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      environment.KACHE_CONFIG = "${configFile}";
    };
  };
}
