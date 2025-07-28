{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.oneleet;
in {
  options.programs.oneleet = {
    enable = mkEnableOption "OneLeet";

    package = mkOption {
      type = types.package;
      default = pkgs.stdenv.mkDerivation {
        name = "oneleet";
        version = "2.0.0-beta";

        src = pkgs.fetchurl {
          url = "https://downloads.oneleet.com/agent/linux/Oneleet_2.0.0-beta.18_amd64.deb";
          sha256 = "sha256-PuYg+NUAM7+PGh0m+m5HuSSweIpy5HdzCdCpoCwkcX8=";
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
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
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
              --add-flags "--password-store=gnome-libsecret"
            echo "Created wrapper for oneleet-agent with libsecret password store flag"
          fi
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
  };
}
