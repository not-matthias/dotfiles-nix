{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.oneleet;

  # Tools the agent/daemon shell out to at runtime: xdg-open to launch the
  # sign-in URL in a browser, plus disk-encryption and user-remediation utils.
  runtimeDeps = with pkgs; [
    xdg-utils
    util-linux
    cryptsetup
    coreutils
    iproute2
    pciutils
    procps
    shadow
    systemd
    getent
  ];
in {
  options.programs.oneleet = {
    enable = mkEnableOption "OneLeet";
    service = {
      enable = mkEnableOption "OneLeet daemon system service (oneleet-daemon)";
    };
    agent = {
      enable = mkEnableOption "OneLeet agent user service (oneleet-agent GUI client)";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.stdenv.mkDerivation {
        name = "oneleet";
        version = "2.2.8";

        src = pkgs.fetchurl {
          url = "https://downloads.oneleet.com/agent/linux/Oneleet_2.2.8_amd64.deb";
          sha256 = "sha256-daB5mwlBNGx0vTxD4N12WmS/R80seQWt6UKKYy4xyHs=";
        };

        nativeBuildInputs = with pkgs; [
          dpkg
          autoPatchelfHook
          makeWrapper
        ];

        buildInputs = with pkgs; [
          alsa-lib
          glib
          gtk3
          libsecret
          gnome-keyring
          libgnome-keyring
          nss
          nspr
          at-spi2-atk
          cups
          dbus
          libdrm
          libxkbcommon
          mesa
          pango
          stdenv.cc.cc
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
        ];

        unpackPhase = ''
          dpkg-deb -x $src . &> /dev/null
        '';

        installPhase = ''
          echo "Installing OneLeet..."
          mkdir -p $out

          # Copy everything from usr/ if it exists
          if [ -d usr ]; then
            cp -R usr/* $out/
          fi

          # Copy everything from opt/ if it exists
          if [ -d opt ]; then
            mkdir -p $out/opt
            cp -R opt/* $out/opt/

            # Create symlinks from opt executables to bin
            mkdir -p $out/bin
            find $out/opt -type f -executable \( -name "*oneleet*" -o -name "*Oneleet*" \) | while read executable; do
              basename=$(basename "$executable")
              # Skip if symlink already exists
              if [ ! -e "$out/bin/''${basename,,}" ]; then
                ln -s "$executable" "$out/bin/''${basename,,}"
                echo "Created symlink for $executable to $out/bin/''${basename,,}"
              fi
            done
          fi

          # Create a wrapper around oneleet-agent to add the password-store flag
          if [ -e "$out/bin/oneleet-agent" ]; then
            mv $out/bin/oneleet-agent $out/bin/oneleet-agent-unwrapped
            makeWrapper $out/bin/oneleet-agent-unwrapped $out/bin/oneleet-agent \
              --prefix LD_LIBRARY_PATH : $out/lib:$out/lib64 \
              --prefix PATH : ${makeBinPath runtimeDeps} \
              --add-flags "--password-store=gnome-libsecret"
            echo "Created wrapper for oneleet-agent with libsecret password store flag"
          fi

          # Fix .desktop files to use the wrapped binary so launchers (e.g. vicinae) work correctly
          for desktop in $(find $out/share/applications -name "*.desktop" 2>/dev/null); do
            sed -i "s|^Exec=.*|Exec=$out/bin/oneleet-agent|" "$desktop"
            echo "Patched Exec= in $desktop"
          done
        '';

        meta = with lib; {
          description = "OneLeet application";
          homepage = "https://oneleet.com";
          license = licenses.unfree;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    # Create direct executables in /usr/bin
    system.activationScripts = {
      createOneLeetLinks = {
        text = ''
          mkdir -p /usr/bin
          ln -sf ${cfg.package}/bin/oneleet-agent /usr/bin/oneleet-agent || true
        '';
        deps = [];
      };
    };

    # Directories the daemon expects (config, logs).
    systemd.tmpfiles.rules = mkIf cfg.service.enable [
      "d /etc/oneleet 0755 root root -"
      "d /var/log/oneleet 0755 root root -"
    ];

    # Run oneleet-daemon as a root system service so the user-launched agent
    # can always reach /tmp/oneleet-daemon.sock without re-authenticating.
    systemd.services.oneleet-daemon = mkIf cfg.service.enable {
      description = "OneLeet daemon";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      path = runtimeDeps;

      serviceConfig = {
        ExecStart = "${cfg.package}/opt/Oneleet/oneleet-daemon";
        Restart = "always";
        RestartSec = 5;
        User = "root";
        # World-readable socket so the user-launched agent can connect.
        UMask = "0000";
      };
    };

    # GUI client that connects to the daemon socket. Runs in the user session.
    systemd.user.services.oneleet-agent = mkIf cfg.agent.enable {
      description = "OneLeet agent (GUI client)";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target" "oneleet-daemon.service"];

      path = runtimeDeps;

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/oneleet-agent";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
