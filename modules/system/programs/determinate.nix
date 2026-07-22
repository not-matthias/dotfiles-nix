{...}: {
  # Disable Determinate Nix's built-in auto-GC (nix.gc weekly, in configuration.nix,
  # handles GC) and opt out of all telemetry + Sentry crash reports.
  environment.etc."determinate/config.json".text = builtins.toJSON {
    garbageCollector.strategy = "disabled";
    telemetry.sentry.endpoint = null;
  };

  # Opt out of all Determinate Nix runtime telemetry (DETSYS_IDS_TELEMETRY=disabled).
  # Set on nix-daemon (runs determinate-nixd, the primary telemetry sender) and in the
  # global env for user nix invocations. environment.variables alone doesn't reach system
  # services, so the service-level setting is required.
  systemd.services.nix-daemon.environment.DETSYS_IDS_TELEMETRY = "disabled";
  environment.variables.DETSYS_IDS_TELEMETRY = "disabled";
}
