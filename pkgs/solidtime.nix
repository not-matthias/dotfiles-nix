{
  lib,
  stdenv,
  pkgs,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  desktop-file-utils,
  cairo,
  pango,
  atk,
  gtk3,
  gdk-pixbuf,
  xorg,
  libgbm,
  expat,
  libxkbcommon,
  alsa-lib,
  nss,
  cups,
  mesa,
  libGL,
  libdrm,
  dbus,
  nspr,
  at-spi2-atk,
  at-spi2-core,
}: let
  pname = "solidtime-desktop";
  version = "0.0.40";
in
  stdenv.mkDerivation rec {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/solidtime-io/solidtime-desktop/releases/download/v${version}/solidtime-x64.tar.gz";
      hash = "sha256-N92PK46Dltq6PgQIOsPdMk09udjLu0FSvhlTzkCl3D8=";
    };

    nativeBuildInputs = [
      makeWrapper
      autoPatchelfHook
      desktop-file-utils
    ];

    buildInputs = with pkgs; [
      cairo
      pango
      atk
      gtk3
      gdk-pixbuf
      xorg.libX11
      xorg.libXext
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXfixes
      xorg.libXrandr
      xorg.libXtst
      xorg.libXScrnSaver
      libgbm
      expat
      xorg.libxcb
      libxkbcommon
      alsa-lib
      nss
      nspr
      cups
      mesa
      libGL
      libglvnd
      libdrm
      dbus
      at-spi2-atk
      at-spi2-core
    ];

    installPhase = ''
            mkdir -p $out/opt/solidtime
            tar -xzf $src -C $out/opt/solidtime

            # Create wrapper script
            mkdir -p $out/bin
            makeWrapper $out/opt/solidtime/solidtime-x64/solidtime $out/bin/solidtime-desktop \
              --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
              --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

            # Desktop entry
            mkdir -p $out/share/applications
            cat > $out/share/applications/solidtime.desktop <<EOF
      [Desktop Entry]
      Name=Solidtime
      Comment=Solidtime Desktop Client
      Exec=$out/bin/solidtime-desktop
      Icon=$out/opt/solidtime/solidtime-x64/resources/app.asar.unpacked/resources/solidtime.png
      Terminal=false
      Type=Application
      Categories=Utility;
      EOF
    '';

    meta = {
      description = "Solidtime Desktop application - time tracking made simple";
      homepage = "https://solidtime.com";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "solidtime-desktop";
      maintainers = [];
    };
  }
