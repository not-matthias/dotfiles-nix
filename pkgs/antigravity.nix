{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libx11,
  libxext,
  libxcomposite,
  libxdamage,
  libxfixes,
  libxrandr,
  libxcb,
  libxkbcommon,
  libxkbfile,
  fontconfig,
  libpulseaudio,
  alsa-lib,
  at-spi2-core,
  dbus,
  gtk3,
  nss,
  nspr,
  mesa,
  libGL,
  libdrm,
  webkitgtk_4_1,
  libsoup_3,
  libsecret,
}: let
  pname = "antigravity";
  version = "2.5.5";
in
  stdenv.mkDerivation rec {
    inherit pname version;

    src = fetchurl {
      name = "antigravity.tar.gz";
      url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz";
      hash = "sha256-DFIzspfSs667Ya9J+JRAEsKVPTYaXrsWl4SQY2kX+DE=";
    };

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      libx11
      libxext
      libxcomposite
      libxdamage
      libxfixes
      libxrandr
      libxcb
      libxkbcommon
      libxkbfile
      fontconfig
      libpulseaudio
      alsa-lib
      at-spi2-core
      dbus
      gtk3
      nss
      nspr
      mesa
      libGL
      libdrm
      webkitgtk_4_1
      libsoup_3
      libsecret
    ];

    dontConfigure = true;
    dontBuild = true;

    libPath = lib.makeLibraryPath buildInputs;

    installPhase = ''
      mkdir -p $out/opt/antigravity
      tar -xzf $src -C $out/opt/antigravity --strip-components=1

      # Make the main binary executable
      chmod +x $out/opt/antigravity/antigravity-ide

      # Create a wrapper script to set up the environment
      mkdir -p $out/bin
      makeWrapper $out/opt/antigravity/antigravity-ide $out/bin/antigravity \
        --prefix LD_LIBRARY_PATH : "${libPath}:$out/opt/antigravity"

      # Install the icon
      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp $out/opt/antigravity/resources/app/resources/linux/code.png \
        $out/share/icons/hicolor/512x512/apps/antigravity.png

      # Create desktop entry
      mkdir -p $out/share/applications
      cat > $out/share/applications/antigravity.desktop <<EOF
      [Desktop Entry]
      Name=Antigravity
      Comment=Collaborative whiteboard application
      Exec=$out/bin/antigravity
      Icon=antigravity
      Type=Application
      Categories=Utility;
      Terminal=false
      StartupNotify=true
      EOF
    '';

    meta = {
      description = "Google Antigravity - collaborative whiteboard application";
      homepage = "https://antigravity.google";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "antigravity";
    };
  }
