{
  lib,
  stdenv,
  pkgs,
  fetchurl,
  makeWrapper,
  makeShellWrapper,
  autoPatchelfHook,
  wrapGAppsHook3,
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
  systemd,
  libpulseaudio,
  pipewire,
  wayland,
  libappindicator-gtk3,
  libdbusmenu,
  fontconfig,
  freetype,
  glib,
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
      makeShellWrapper
      autoPatchelfHook
      wrapGAppsHook3
    ];

    buildInputs = [
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
      xorg.libxcb
      xorg.libxshmfence
      libgbm
      expat
      libxkbcommon
      alsa-lib
      libpulseaudio
      pipewire
      nss
      nspr
      cups
      mesa
      libGL
      pkgs.libglvnd
      libdrm
      dbus
      at-spi2-atk
      at-spi2-core
      systemd
      wayland
      libappindicator-gtk3
      libdbusmenu
      fontconfig
      freetype
      glib
    ];

    # Prevent double-wrapping by wrapGAppsHook3
    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt/solidtime
      tar -xzf $src -C $out/opt/solidtime

      runHook postInstall
    '';

    # Build comprehensive library path for runtime
    libPath = lib.makeLibraryPath buildInputs;

    preFixup = ''
                  # Manually wrap with both GApps variables and library path
                  mkdir -p $out/bin
                  makeWrapper $out/opt/solidtime/solidtime-x64/solidtime $out/bin/solidtime-desktop \
                    "''${gappsWrapperArgs[@]}" \
                    --prefix LD_LIBRARY_PATH : "${libPath}:$out/opt/solidtime/solidtime-x64" \
                    --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

                  # Create desktop entry with URL scheme handler
                  mkdir -p $out/share/applications
                  cat > $out/share/applications/solidtime.desktop <<EOF
      [Desktop Entry]
      Name=Solidtime
      Comment=Solidtime Desktop Client
      Exec=$out/bin/solidtime-desktop %u
      Icon=$out/opt/solidtime/solidtime-x64/resources/app.asar.unpacked/resources/solidtime.png
      Terminal=false
      Type=Application
      Categories=Utility;
      MimeType=x-scheme-handler/solidtime;
      StartupNotify=true
      SingleMainWindow=true
      DBusActivatable=false
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
