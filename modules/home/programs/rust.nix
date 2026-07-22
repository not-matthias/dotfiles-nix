# TODO: Setup wild linker, see: https://github.com/davidlattimore/wild/blob/main/nix/nix.md
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.rust;
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

    # Profile knobs CAN shrink target/, but a profile set in
    # ~/.cargo/config.toml OVERRIDES the project's Cargo.toml [profile.dev]
    # (per Cargo docs) — so these are opt-in, defaulting to "emit nothing".
    # sccache does NOT reduce target/ — it caches rustc output in its own dir
    # while still materializing artifacts into each project's target/.
    profile = {
      devDebug = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "line-tables-only";
        description = ''
          [profile.dev] debug level to force globally, e.g.
          "line-tables-only" (keeps backtraces, drops most debug info,
          ~halves target/). null emits nothing.

          WARNING: a profile in ~/.cargo/config.toml OVERRIDES the
          project's Cargo.toml [profile.dev] (Cargo docs), so setting this
          forces the value on EVERY project, defeating per-project debug
          settings (e.g. projects needing full debug for gdb/lldb).
        '';
      };
      disableIncremental = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Force [profile.dev] incremental = false globally. Removes the
          target/debug/incremental/ tree at the cost of slower rebuilds.
          Same override caveat as devDebug — affects every project.
        '';
      };
    };

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
          default = ["${config.home.homeDirectory}/Documents/technical/git"];
          description = "Roots cargo-sweep -r walks for Cargo.toml.";
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
          cargo-wipe
          cargo-nextest

          # (fenix.complete.withComponents [
          #   "cargo"
          #   "clippy"
          #   "rust-src"
          #   "rustc"
          #   "rustfmt"
          #   "rust-analyzer"
          # ])
        ]
        ++ lib.optionals cfg.maintenance.enable [
          cargo-sweep
          cargo-cache
        ];

      sessionPath = [
        "$HOME/.cargo/bin"
      ];
    };

    # Emit [profile.dev] only when explicitly opted in. An empty
    # [profile.dev] table is avoided on purpose (its override semantics are
    # ambiguous and could reset a project's dev profile to defaults).
    home.file.".cargo/config.toml".source = (pkgs.formats.toml {}).generate "cargo-config" ({
        # Fails with: `rustc: symbol lookup error: rustc: undefined symbol: _ZN3std2rt19lang_start_internal17h4172e5a0738dcd76E`
        target.x86_64-unknown-linux-gnu = {
          # rustflags = ["-C" "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"];
          # rustflags = ["-Zthreads=8"];
          # rustflags = ["-Clink-arg=-fuse-ld=lld" "-Zthreads=8" "-Csymbol-mangling-version=v0"];
        };
        build = {
          # rustflags = ["-Clink-arg=-fuse-ld=lld" "-Zthreads=8" "-Csymbol-mangling-version=v0"];
          # rustc-wrapper = "${pkgs.sccache}/bin/sccache";
        };

        # unstable = {
        #   build-dir-new-layout = true;
        #   gc = true;
        #   gitoxide = true;
        #   mtime-on-use = true;
        #   checksum-freshness = true;
        #   fine-grain-locking = true;
        # };
        alias = {
          b = "build";
          c = "check";
          t = "nextest run";
          tr = "nextest run --release";
          r = "run";
          rr = "run --release";
          br = "build --release";
        };
      }
      // lib.optionalAttrs (cfg.profile.devDebug != null || cfg.profile.disableIncremental) {
        profile.dev =
          (lib.optionalAttrs (cfg.profile.devDebug != null) {debug = cfg.profile.devDebug;})
          // (lib.optionalAttrs cfg.profile.disableIncremental {incremental = false;});
      });

    # Single maintenance job (sweep then cache), behind a guard that skips
    # while a cargo/rustc build is active. The guard is best-effort (TOCTOU:
    # a build may start after the check passes); true exclusion would need a
    # shared lock with Cargo, which cargo-sweep does not take. Persistent=true
    # keeps the weekly cadence; a catch-up run skips if busy at login.
    systemd.user.services.cargo-maintenance = lib.mkIf cfg.maintenance.enable {
      Unit = {Description = "Cargo maintenance: sweep stale target/ + autoclean ~/.cargo";};
      Service = {
        Type = "oneshot";
        ExecCondition = "${pkgs.bash}/bin/sh -c 'if ${pkgs.procps}/bin/pgrep -u ${config.home.username} -x cargo >/dev/null 2>&1 || ${pkgs.procps}/bin/pgrep -u ${config.home.username} -x rustc >/dev/null 2>&1; then echo \"cargo/rustc running, skipping cargo-maintenance\"; exit 1; fi'";
        # writeShellScript places the executable at the store path root (no /bin/).
        ExecStart = "${maintenanceScript}";
      };
    };
    systemd.user.timers.cargo-maintenance = lib.mkIf cfg.maintenance.enable {
      Unit = {Description = "Weekly cargo maintenance";};
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      Install = {WantedBy = ["timers.target"];};
    };
  };
}
