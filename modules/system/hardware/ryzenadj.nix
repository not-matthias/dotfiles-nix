{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: let
  cfg = config.hardware.ryzenadj;

  # Tuned for AMD Ryzen 7 7840U (Phoenix) on Framework 13.
  #
  # Framework BIOS 3.09+ clamps STAPM to ~28W after roughly a minute of load,
  # which is why all-core boost collapses to ~3GHz even at low Tctl. These
  # limits raise the sustained/peak ceiling (STAPM/slow/fast 45/45/51W) and
  # stretch the averaging window so the clamp engages much later. The SMU
  # silently caps direct STAPM writes near 43W, so 45W is best-effort.
  #
  # Thermals are unconstrained: fw-fanctrl runs the "deaf" strategy (100% fan)
  # and tctl-temp is 100C (junction max 105C). VRM current limits are left at
  # stock — they protect the mainboard and are not the binding constraint.
  #
  # Access: the SMU mailbox SET commands use PCI config space and apply without
  # /dev/mem. The -i info dump reads the memory-mapped power metric table via
  # /dev/mem, which CONFIG_IO_STRICT_DEVMEM blocks on this kernel, so ryzenadj
  # exits non-zero even though the SETs applied. `|| true` keeps the service
  # green so the reapply timer stays active; the full output (incl. "Successfully
  # set") is logged to the journal for auditing. PPD -> amd_pmf -> PMFW mailbox
  # overwrites these SMU values, so the service re-applies on a timer (AC only).
  ryzenadjTune = pkgs.writeShellScript "ryzenadj-tune" ''
    ${unstable.ryzenadj}/bin/ryzenadj \
      --stapm-limit=45000 \
      --fast-limit=51000 \
      --slow-limit=45000 \
      --tctl-temp=100 \
      --stapm-time=500 \
      --slow-time=500 \
      -i || true
  '';
in {
  options.hardware.ryzenadj = {
    enable = lib.mkEnableOption "ryzenadj power-limit tuning for max sustained boost";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [unstable.ryzenadj];

    systemd.services.ryzenadj-tune = {
      description = "Apply ryzenadj max-performance power limits";
      # Run after PPD so the EC's platform-profile write lands first and
      # ryzenadj's direct SMU write wins (until the next PMF re-assert).
      after = ["power-profiles-daemon.service"];
      wants = ["power-profiles-daemon.service"];
      wantedBy = ["multi-user.target"];
      # Only enforce the high-power envelope on AC; the battery cannot deliver it.
      unitConfig.ConditionACPower = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ryzenadjTune;
      };
    };

    # PPD/PMF periodically re-asserts vendor power limits, overwriting
    # ryzenadj. Re-apply to keep the raised ceiling in effect.
    systemd.timers.ryzenadj-tune = {
      description = "Re-apply ryzenadj power limits";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "15s";
        OnUnitActiveSec = "60s";
      };
    };
  };
}
