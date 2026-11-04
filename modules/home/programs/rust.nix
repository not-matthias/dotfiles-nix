{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.rust;
  # The home generation roots the libraries used to repair rustup's toolchains.
  rustupRepatch = pkgs.writeShellApplication {
    name = "rustup-repatch";
    runtimeInputs = with pkgs; [patchelf findutils gnused coreutils];
    runtimeEnv = {
      DYNAMIC_LINKER = pkgs.stdenv.cc.bintools.dynamicLinker;
      ZLIB_LIB = lib.makeLibraryPath [pkgs.zlib];
    };
    text = builtins.readFile ./rustup-repatch.sh;
  };
  # One job: sweep stale target/ artifacts, then autoclean ~/.cargo.
  # Runs behind an ExecCondition that skips while cargo/rustc are active
  # (cargo-sweep deletes from target/ without Cargo's lock, so racing a
  # live build is destructive).
  maintenanceScript = pkgs.writeShellScript "cargo-maintenance" ''
    # Run both independent jobs; capture any failure so the unit
    # status reflects it (fail loudly) without skipping the cache job when
    # sweep hits a broken project.
    rc=0
    ${pkgs.cargo-sweep}/bin/cargo-sweep sweep -r -t ${toString cfg.maintenance.sweep.maxAgeDays} ${lib.escapeShellArgs cfg.maintenance.sweep.scanPaths} || rc=$?
    ${pkgs.cargo-cache}/bin/cargo-cache --autoclean || rc=$?
    exit "$rc"
  '';
in {
  options.programs.rust = {
    enable = lib.mkEnableOption "rust";

    maintenance = {
      enable = lib.mkEnableOption "weekly cargo maintenance (sweep stale target/ + autoclean ~/.cargo, behind a no-active-build guard)";
      sweep = {
        maxAgeDays = lib.mkOption {
          type = lib.types.ints.positive;
          default = 30;
          description = "Remove target/ artifacts unused for more than this many days.";
        };
        scanPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Git repository roots cargo-sweep walks for Cargo.toml. Set per host when Rust maintenance is enabled.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs;
        [
          # Required for rustup, otherwise we have linker errors:
          # https://github.com/NixOS/nixpkgs/issues/103642
          gcc
          rustup

          # Dependencies for building Rust packages
          pkg-config
          openssl
          zlib

          # Cargo tools
          cargo-edit
          cargo-expand
          cargo-udeps
          cargo-nextest
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [rustupRepatch]
        ++ lib.optionals cfg.maintenance.enable [
          cargo-sweep
          cargo-cache
        ];

      sessionPath = ["$HOME/.cargo/bin"];
    };

    home.activation.rustupRepatch = lib.mkIf pkgs.stdenv.isLinux (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${rustupRepatch}/bin/rustup-repatch
      ''
    );

    home.file.".cargo/config.toml".source = (pkgs.formats.toml {}).generate "cargo-config" {
      alias = {
        b = "build";
        c = "check";
        t = "nextest run";
        tr = "nextest run --release";
        r = "run";
        rr = "run --release";
        br = "build --release";
      };
    };

    # Single maintenance job (sweep then cache), behind a guard that skips
    # while a cargo/rustc build is active. The guard is best-effort (TOCTOU:
    # a build may start after the check passes); true exclusion would need a
    # shared lock with Cargo, which cargo-sweep does not take. Persistent=true
    # keeps the weekly cadence; a catch-up run skips if busy at login.
    systemd.user = lib.mkIf cfg.maintenance.enable {
      services.cargo-maintenance = {
        Unit.Description = "Cargo maintenance: sweep stale target/ + autoclean ~/.cargo";
        Service = {
          Type = "oneshot";
          ExecCondition = "${pkgs.bash}/bin/sh -c 'if ${pkgs.procps}/bin/pgrep -u ${config.home.username} -x \"cargo|rustc\" >/dev/null 2>&1; then echo \"cargo/rustc running, skipping cargo-maintenance\"; exit 1; fi'";
          # writeShellScript places the executable at the store path root (no /bin/).
          ExecStart = "${maintenanceScript}";
        };
      };
      timers.cargo-maintenance = {
        Unit.Description = "Weekly cargo maintenance";
        Timer = {
          OnCalendar = "weekly";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
