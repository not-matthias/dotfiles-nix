{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.sccache;
in {
  options.programs.sccache.enable = mkEnableOption "sccache, a shared compilation cache";

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.sccache];
    environment.variables = {
      RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
      SCCACHE_CACHE_SIZE = "100G";
      CARGO_INCREMENTAL = "0";
    };
  };
}
