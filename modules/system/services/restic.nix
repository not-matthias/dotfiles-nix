# TODO: Allows zfs snapshots to prevent backing up corrupted data (e.g. from a service)
# - Do it like here: https://github.com/JulianFP/NixOSConfig/blob/5d2b2dea785d0bd610c6638e282528eeb0e8539d/mainserver/backup.nix#L32-L40
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkOption types;

  mkNotificationScript = {
    title,
    successMessage,
    failureMessage,
    tags,
    serviceName,
  }: ''
    if [ $EXIT_STATUS -eq 0 ]; then
      # Success notification
      if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
        ${pkgs.libnotify}/bin/notify-send --urgency=low \
          "${title} Success" \
          "${successMessage}"
      fi

      ${pkgs.curl}/bin/curl -d "${successMessage} on $(${pkgs.nettools}/bin/hostname)" \
        -H "Title: ${title} Success" \
        -H "Priority: low" \
        -H "Tags: ${tags},success" \
        https://ntfy.sh/desktop-zfs
    else
      # Failure notification with journal output
      JOURNAL_OUTPUT=$(${pkgs.systemd}/bin/journalctl -u "${serviceName}" -n 5 -o cat 2>/dev/null || echo "No journal output available")

      # Send desktop notification (requires user session)
      if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
        ${pkgs.libnotify}/bin/notify-send --urgency=critical \
          "${title} Failed" \
          "$JOURNAL_OUTPUT"
      fi

      ${pkgs.curl}/bin/curl -d "${failureMessage} on $(${pkgs.nettools}/bin/hostname)" \
        -H "Title: ${title} Failed" \
        -H "Priority: urgent" \
        -H "Tags: ${tags},failure" \
        -d "$JOURNAL_OUTPUT" \
        https://ntfy.sh/desktop-zfs
    fi
  '';

  mkBackupConfig = {
    name,
    repository,
    paths,
    extraPaths ? [],
    environmentFile ? null,
    prepareCommand ? "",
    timerConfig,
    notificationTitle,
    notificationTags,
  }: let
    allExcludes =
      defaultExcludes
      ++ config.services.restic.excludes;

    baseConfig = {
      initialize = true;
      inherit repository timerConfig;
      passwordFile = config.age.secrets.restic-password.path;
      paths = paths ++ extraPaths ++ config.services.restic.paths;
      exclude = allExcludes;
      inherit pruneOpts extraBackupArgs;

      backupPrepareCommand = ''
        ${prepareCommand}

        # Remove stale locks
        ${pkgs.restic}/bin/restic unlock || true
      '';

      # Built-in cleanup command for notifications
      backupCleanupCommand = mkNotificationScript {
        title = notificationTitle;
        successMessage = "${notificationTitle} completed successfully";
        failureMessage = "${notificationTitle} failed";
        tags = notificationTags;
        serviceName = "restic-backups-${name}";
      };
    };
  in
    if environmentFile != null
    then baseConfig // {inherit environmentFile;}
    else baseConfig;

  # Conservative excludes - only exclude what's truly unnecessary
  defaultExcludes = [
    # ==============================================================================
    # System Caches & Temporary Files
    # ==============================================================================
    ".cache"
    ".config/*/Cache"
    ".config/*/Code Cache"
    ".config/*/GPUCache"
    ".config/*/DawnCache"
    ".config/*/DawnWebGPUCache"
    ".config/*/DawnGraphiteCache"
    ".config/*/CachedData"
    ".config/*/CachedExtensionVSIXs"
    ".config/*/CachedConfigurations"
    ".config/*/CachedProfilesData"
    ".cache/mesa_shader_cache"
    ".cache/mesa_shader_cache_db"
    ".cache/qtshadercache*"
    ".cache/neo_compiler_cache"
    ".config/*/GrShaderCache"
    ".config/*/GraphiteDawnCache"
    ".config/*/ShaderCache"
    ".cache/thumbnails"
    ".thumbnails"
    ".tmp"
    ".temp"
    "tmp"
    "temp"
    "*.tmp"
    "*.temp"
    "*.swp"
    "*.swo"
    "*~"
    ".DS_Store"
    "Thumbs.db"
    ".Trash"

    # ==============================================================================
    # Browser Caches (preserve bookmarks, settings, etc.)
    # ==============================================================================
    ".mozilla/*/cache*"
    ".mozilla/*/Cache*"
    ".mozilla/*/crashes"
    ".mozilla/*/minidumps"
    ".config/google-chrome*/*/Cache*"
    ".config/google-chrome*/*/Code Cache*"
    ".config/google-chrome*/*/GPUCache*"
    ".config/google-chrome*/*/Service Worker/CacheStorage*"
    ".config/chromium*/*/Cache*"
    ".config/chromium*/*/Code Cache*"
    ".config/chromium*/*/GPUCache*"
    ".config/vivaldi/*/Cache*"
    ".surf/cache"
    ".minecraft/webcache"

    # ==============================================================================
    # Version Control System Metadata
    # ==============================================================================
    # Local VCS internals (keep .git for active projects)
    # Git should be backed up somewhere rather than by ourselves
    # TODO: Does this work for gitea?
    ".git"
    ".svn"
    ".hg"

    # Full VCS directories (uncomment if you work offline a lot)
    # "**/.git"
    # "**/.svn"
    # "**/.hg"

    # ==============================================================================
    # Language & Framework Specific Artifacts
    # ==============================================================================

    # JavaScript / TypeScript / Node.js
    "**/node_modules"
    "**/bower_components"
    "**/.npm"
    "**/.next"
    "**/.nuxt"

    # Python
    "**/__pycache__"
    "**/*.pyc"
    "**/*.pyo"
    "**/venv"
    "**/.venv"
    "**/*-venv" # Covers python-venv, etc.
    "**/.env"
    "**/pip-wheel-metadata"
    "**/.pytest_cache"
    "**/.mypy_cache"

    # Java / Kotlin / Scala (Maven, Gradle, sbt)
    "**/.gradle"
    "**/.gradle/caches"
    "**/.gradle/.tmp"
    "**/build/libs"
    "**/*.jar"
    "**/*.war"

    # Go
    "**/vendor"
    "**/go/pkg"

    # Rust
    "**/target/debug"
    "**/target/release"

    # Zig
    "**/zig-cache"
    "**/zig-out"
    "**/.zig-cache"

    # Bazel
    "**/bazel-*"
    "**/.bazel-*"

    # C / C++
    "**/*.o"
    "**/*.obj"
    "**/*.so"
    "**/*.a"
    "**/*.dll"
    "**/*.exe"
    "**/CMakeCache.txt"
    "**/CMakeFiles"

    # General build artifacts
    "**/build"
    "**/.build"
    "**/dist"
    "**/result"
    "**/.devenv"
    "**/.sst"
    "**/generated"

    # ==============================================================================
    # IDE and Editor Configuration/Cache
    # ==============================================================================
    "**/.idea"
    "**/.vscode-server"
    ".promptfoo/cache"
    ".mx/cache"
    ".aider/caches"
    ".compose-cache"
    ".openjfx/cache"
    ".proto/cache"

    # ==============================================================================
    # Containers & Virtualization
    # ==============================================================================
    # VM disk images
    "**/*.vdi"
    "**/*.vmdk"
    "**/*.img"
    "**/*.qcow2"
    "*.iso"

    # Docker
    ".docker/containers"
    ".docker/image"
    ".docker/overlay2"
    ".docker/volumes"
    ".local/share/docker"

    # Other virtualization
    ".podman/storage"
    ".vagrant/boxes"
    ".config/VirtualBox/VMs"
    ".distrobox-*"

    # ==============================================================================
    # Development Tools & Package Managers
    # ==============================================================================
    ".npm/_cacache"
    ".pub-cache"
    ".dartServer/.pub-package-details-cache"
    ".rustup/tmp"
    ".cdk/cache"
    ".debug/tmp"
    ".debug/[mbcache]"

    # ==============================================================================
    # Gaming & Entertainment
    # ==============================================================================
    ".steam/steamapps/common"
    ".steam/steamapps/downloading"
    ".steam/logs"
    ".wine*/drive_c/windows/temp"
    ".wine*/drive_c/users/*/Temp"
    ".BitwigStudio/cache"

    # ==============================================================================
    # Application Logs & Temporary Data
    # ==============================================================================
    "*/logs"
    ".config/*/logs"
    ".local/share/*/logs"
    ".local/state/*/logs"
    ".config/obs-studio/logs"
    ".config/Lidarr/logs"
    ".config/Readarr/logs"
    "*.log"

    # Performance profiling data
    "perf.data"
    "perf.data.*"
    "perf.jit.data"
    "perf.jit.data.*"

    # Application temporary
    ".zoom"
    ".gemini/tmp"
    ".config/joplin/tmp"
    ".config/joplin/cache"
    ".config/calibre/caches"
    ".config/zdoom/cache"

    "minecraft-data/libraries/"
    "minecraft-data/plugins/"

    # ==============================================================================
    # Large Binary Files
    # ==============================================================================
    "*.deb"
    "*.rpm"
    "*.dmg"
    "*.msi"
  ];

  pruneOpts = [
    "--keep-daily 7"
    "--keep-weekly 4"
    "--keep-monthly 3"
    "--keep-yearly 1"
    "--max-unused 10%"
    "--repack-cacheable-only"
  ];

  extraBackupArgs = [
    "--exclude-if-present=.nobak"
    "--exclude-caches"
  ];
in {
  options.services.restic = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable restic backup service";
    };

    paths = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Paths to include in backup";
    };

    excludes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Paths to exclude from backup";
    };

    enablePreviewScript = mkOption {
      type = types.bool;
      default = true;
      description = "Enable restic-preview script for testing backup patterns";
    };

    localBackup = mkOption {
      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable local incremental backup";
          };

          paths = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Paths to include in local backup";
          };

          repository = mkOption {
            type = types.str;
            default = "/var/lib/restic/local-backup";
            description = "Local backup repository path";
          };

          schedule = mkOption {
            type = types.str;
            default = "hourly";
            description = "Backup schedule (systemd timer format)";
          };
        };
      };
      default = {};
      description = "Local backup configuration";
    };

    remoteBackup = mkOption {
      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable remote backup to Backblaze B2";
          };

          paths = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Paths to include in remote backup";
          };

          repository = mkOption {
            type = types.str;
            description = "Remote backup repository URL (e.g., b2:bucket-name:/path)";
          };

          schedule = mkOption {
            type = types.str;
            default = "daily";
            description = "Backup schedule (systemd timer format)";
          };

          randomizedDelay = mkOption {
            type = types.str;
            default = "1h";
            description = "Randomized delay for backup start";
          };
        };
      };
      default = {};
      description = "Remote backup configuration";
    };
  };

  config = mkIf config.services.restic.enable {
    age.secrets.restic-password.file = ../../../secrets/restic-password.age;
    age.secrets.b2-restic-env = lib.mkIf config.services.restic.remoteBackup.enable {
      file = ../../../secrets/b2-restic-env.age;
    };

    environment.systemPackages = with pkgs;
      [
        restic
        libnotify
        backblaze-b2
        curl
        dust
        ncdu
        redu
      ]
      ++ lib.optionals config.services.restic.enablePreviewScript [
        (pkgs.writeScriptBin "restic-preview" ''
          #!/usr/bin/env bash
          # Restic backup preview script - shows what would be backed up with dry-run
          # Usage: restic-preview [local|remote] [--full]
          #
          # Examples:
          #   restic-preview           # Preview local backup with filtered output
          #   restic-preview local     # Same as above
          #   restic-preview --full    # Show full dry-run output
          #   restic-preview remote    # Preview remote backup (if configured)

          set -e

          BACKUP_TYPE="local"
          SHOW_FULL=false

          # Parse arguments
          while [[ $# -gt 0 ]]; do
            case $1 in
              local|remote)
                BACKUP_TYPE="$1"
                shift
                ;;
              --full)
                SHOW_FULL=true
                shift
                ;;
              *)
                echo "Usage: restic-preview [local|remote] [--full]"
                echo "  local:  Preview local backup (default)"
                echo "  remote: Preview remote backup (if configured)"
                echo "  --full: Show complete dry-run output"
                exit 1
                ;;
            esac
          done

          echo "Restic Backup Preview ($BACKUP_TYPE)"
          echo "====================="
          echo

          # Set repository and paths based on backup type
          if [[ "$BACKUP_TYPE" == "local" ]]; then
            REPOSITORY="${config.services.restic.localBackup.repository}"
            PATHS="${lib.concatStringsSep " " (
            (config.services.restic.localBackup.paths or [])
            ++ config.services.restic.paths
          )}"
          elif [[ "$BACKUP_TYPE" == "remote" ]]; then
            ${
            if config.services.restic.remoteBackup.enable
            then ''
              REPOSITORY="${config.services.restic.remoteBackup.repository}"
              PATHS="${lib.concatStringsSep " " (
                (config.services.restic.remoteBackup.paths or [])
                ++ config.services.restic.paths
              )}"
            ''
            else ''
              echo "Error: Remote backup is not enabled in configuration"
              exit 1
            ''
          }
          fi

          if [[ -z "$PATHS" ]]; then
            echo "Error: No backup paths configured for $BACKUP_TYPE backup"
            exit 1
          fi

          echo "Repository: $REPOSITORY"
          echo "Paths: $PATHS"
          echo "Password file: ${config.age.secrets.restic-password.path}"
          echo

          # Prepare environment for remote backup
          if [[ "$BACKUP_TYPE" == "remote" ]]; then
            ${
            if config.services.restic.remoteBackup.enable
            then ''
              # Source environment file for B2 credentials
              set -a
              source ${config.age.secrets.b2-restic-env.path}
              set +a
            ''
            else ''
              # Environment already set up above, or will error out
              true
            ''
          }
          fi

          # Run dry-run backup
          echo "Running dry-run backup..."
          echo "========================"

          RESTIC_CMD="${pkgs.restic}/bin/restic -r $REPOSITORY --password-file ${config.age.secrets.restic-password.path} backup --dry-run --verbose=2 ${
            lib.concatStringsSep " " (
              map (path: "--exclude '${path}'")
              (defaultExcludes ++ config.services.restic.excludes)
            )
          } --exclude-if-present=.nobak --exclude-caches $PATHS"

          if [[ "$SHOW_FULL" == "true" ]]; then
            eval "$RESTIC_CMD"
          else
            echo "Filtered output (use --full for complete output):"
            echo
            eval "$RESTIC_CMD" 2>&1 | grep -E "(excluded|would add|would backup|Files:|Dirs:|Added to the repo:)" | head -50
            echo
            echo "..."
            echo
            echo "Summary from dry-run:"
            eval "$RESTIC_CMD" 2>&1 | grep -E "(Files:|Dirs:|Added to the repo:|processed.*in)"
          fi

          echo
          echo "Preview complete."
          echo "Tips:"
          echo "  - Create a .nobak file in directories you want to exclude"
          echo "  - Use --exclude-file for custom exclude patterns"
          echo "  - Files matching exclude patterns are automatically skipped"
        '')

        (pkgs.writeScriptBin "restic-usage" ''
          #!/usr/bin/env bash
          # Restic backup usage analyzer - shows disk usage of local backup paths with exclude filtering
          # Usage: restic-usage [--interactive]
          #
          # Examples:
          #   restic-usage           # Show usage for local backup paths
          #   restic-usage --interactive  # Interactive mode with ncdu

          set -e

          INTERACTIVE=false

          # Parse arguments
          while [[ $# -gt 0 ]]; do
            case $1 in
              --interactive|-i)
                INTERACTIVE=true
                shift
                ;;
              *)
                echo "Usage: restic-usage [--interactive]"
                echo "  --interactive: Use interactive ncdu for browsing"
                exit 1
                ;;
            esac
          done

          echo "Restic Local Backup Usage Analysis"
          echo "=================================="
          echo

          # Set paths for local backup
          PATHS=(${lib.concatStringsSep " " (
            map (path: ''"${path}"'') (
              (config.services.restic.localBackup.paths or [])
              ++ config.services.restic.paths
            )
          )})

          if [[ ''${#PATHS[@]} -eq 0 ]]; then
            echo "Error: No backup paths configured for local backup"
            exit 1
          fi

          echo "Analyzing paths: ''${PATHS[*]}"
          echo

          if [[ "$INTERACTIVE" == "true" ]]; then
            echo "Starting interactive mode with ncdu..."
            echo "Note: This shows ALL files (excludes not applied in interactive mode)"
            echo

            # Use ncdu for interactive browsing
            for path in "''${PATHS[@]}"; do
              if [[ -d "$path" ]]; then
                echo "Opening ncdu for: $path"
                ${pkgs.ncdu}/bin/ncdu "$path"
              else
                echo "Path not found or not a directory: $path"
              fi
            done
          else
            echo "Disk usage analysis (excludes applied):"
            echo "======================================"
            echo

            # Convert exclude patterns to regex for dust
            EXCLUDE_REGEXES=""
            ${lib.concatStringsSep "\n" (map (
            pattern: let
              # Convert glob patterns to regex patterns
              regex =
                builtins.replaceStrings
                ["**/" "*" "." "?" "[" "]" "^" "$"]
                [".*/" ".*" "\\." "." "\\[" "\\]" "\\^" "\\$"]
                pattern;
            in ''
              if [[ -n "$EXCLUDE_REGEXES" ]]; then
                EXCLUDE_REGEXES="$EXCLUDE_REGEXES|${regex}"
              else
                EXCLUDE_REGEXES="${regex}"
              fi
            ''
          ) (defaultExcludes ++ config.services.restic.excludes))}

            # Use dust for analysis with exclude patterns
            for path in "''${PATHS[@]}"; do
              if [[ -d "$path" ]]; then
                echo "=== $path ==="

                if [[ -n "$EXCLUDE_REGEXES" ]]; then
                  # Use dust with invert filter to exclude patterns
                  ${pkgs.dust}/bin/dust -d 3 -r -v "$EXCLUDE_REGEXES" "$path" 2>/dev/null || {
                    echo "Using basic dust for $path..."
                    ${pkgs.dust}/bin/dust -d 3 -r "$path" 2>/dev/null || {
                      echo "Using basic du for $path..."
                      ${pkgs.coreutils}/bin/du -sh "$path" 2>/dev/null || echo "Cannot analyze $path"
                    }
                  }
                else
                  # No excludes, use dust normally
                  ${pkgs.dust}/bin/dust -d 3 -r "$path" 2>/dev/null || {
                    echo "Using basic du for $path..."
                    ${pkgs.coreutils}/bin/du -sh "$path" 2>/dev/null || echo "Cannot analyze $path"
                  }
                fi
                echo
              else
                echo "Path not found or not a directory: $path"
              fi
            done

            echo "Summary:"
            echo "========"
            echo "Total paths analyzed: ''${#PATHS[@]}"
            echo "Exclude patterns applied: ${toString (builtins.length (defaultExcludes ++ config.services.restic.excludes))}"
            echo
            echo "Note: This analysis applies the same exclude patterns used by restic local backup"
            echo "      Use --interactive for browsing all files without exclusions"
          fi
        '')

        (pkgs.writeScriptBin "restic-local" ''
          #!/usr/bin/env bash
          set -e

          export RESTIC_REPOSITORY="${config.services.restic.localBackup.repository}"
          export RESTIC_PASSWORD_FILE="${config.age.secrets.restic-password.path}"

          exec ${pkgs.restic}/bin/restic "$@"
        '')

        (pkgs.writeScriptBin "restic-remote" ''
          #!/usr/bin/env bash
          set -e
          set -e

          ${
            if config.services.restic.remoteBackup.enable
            then ''
              export RESTIC_REPOSITORY="${config.services.restic.remoteBackup.repository}"
              export RESTIC_PASSWORD_FILE="${config.age.secrets.restic-password.path}"

              # Source environment file for B2 credentials
              set -a
              source ${config.age.secrets.b2-restic-env.path}
              set +a

              exec ${pkgs.restic}/bin/restic "$@"
            ''
            else ''
              echo "Remote backup not enabled"
              exit 1
            ''
          }
        '')

        (pkgs.writeScriptBin "redu-local" ''
          #!/usr/bin/env bash
          set -e

          export RESTIC_REPOSITORY="${config.services.restic.localBackup.repository}"
          export RESTIC_PASSWORD_FILE="${config.age.secrets.restic-password.path}"

          exec ${pkgs.redu}/bin/redu "$@"
        '')

        (pkgs.writeScriptBin "redu-remote" ''
          #!/usr/bin/env bash
          set -e

          ${
            if config.services.restic.remoteBackup.enable
            then ''
              export RESTIC_REPOSITORY="${config.services.restic.remoteBackup.repository}"
              export RESTIC_PASSWORD_FILE="${config.age.secrets.restic-password.path}"

              # Source environment file for B2 credentials
              set -a
              source ${config.age.secrets.b2-restic-env.path}
              set +a

              exec ${pkgs.redu}/bin/redu "$@"
            ''
            else ''
              echo "Remote backup not enabled"
              exit 1
            ''
          }
        '')
      ];

    services.restic.backups = lib.mkMerge [
      (lib.mkIf config.services.restic.localBackup.enable {
        local = mkBackupConfig {
          name = "local";
          repository = config.services.restic.localBackup.repository;
          paths = config.services.restic.localBackup.paths;
          timerConfig = {
            OnCalendar = config.services.restic.localBackup.schedule;
            Persistent = true;
          };
          notificationTitle = "Local Backup";
          notificationTags = "backup,local,restic";
        };
      })

      (lib.mkIf config.services.restic.remoteBackup.enable {
        remote = mkBackupConfig {
          name = "remote";
          repository = config.services.restic.remoteBackup.repository;
          paths = config.services.restic.remoteBackup.paths;
          environmentFile = config.age.secrets.b2-restic-env.path;
          timerConfig = {
            OnCalendar = config.services.restic.remoteBackup.schedule;
            Persistent = true;
            RandomizedDelaySec = config.services.restic.remoteBackup.randomizedDelay;
          };
          notificationTitle = "Remote Backup";
          notificationTags = "backup,remote,restic";
        };
      })

      # Remote/NAS backup (less frequent, more selective)
      # (lib.mkIf config.services.restic.nasBackup {
      # nas = {
      #   initialize = true;
      #   repositoryFile = "/var/lib/restic/nas-repository";
      #   passwordFile = config.age.secrets.restic-password.path;
      #   paths = [
      #     "/home"
      #     "/etc"
      #   ] ++ config.services.restic.paths;
      #   timerConfig = {
      #     OnCalendar = "daily";
      #     Persistent = true;
      #     RandomizedDelaySec = "1h";
      #   };
      #   exclude = exclude ++ [
      #     "/home/*/.cache"
      #     "/home/*/.local/share/Trash"
      #     "/home/*/.mozilla/firefox/*/cache*"
      #     "/home/*/.config/google-chrome/*/Cache*"
      #     "/home/*/.config/Code/CachedData"
      #     "/home/*/.vscode/extensions/*/node_modules"
      #     "/home/*/Downloads"
      #     "/home/*/.local/share/Steam"
      #     "/home/*/.steam"
      #   ] ++ config.services.restic.additionalExcludes;
      #   pruneOpts = pruneOpts;
      #   extraBackupArgs = extraBackupArgs;

      #   # Alert on backup failure
      #   backupCleanupCommand = ''
      #     if [ $EXIT_STATUS -ne 0 ]; then
      #       ${pkgs.curl}/bin/curl -d "Restic backup failed with exit code $EXIT_STATUS" \
      #         -H "Title: Backup Failed" \
      #         -H "Priority: urgent" \
      #         -H "Tags: backup,failure" \
      #         https://ntfy.sh/your-topic-name
      #     else
      #       ${pkgs.curl}/bin/curl -d "Restic backup completed successfully" \
      #         -H "Title: Backup Success" \
      #         -H "Priority: low" \
      #         -H "Tags: backup,success" \
      #         https://ntfy.sh/your-topic-name
      #     fi
      #   '';
      # };
      # })
    ];
  };
}
