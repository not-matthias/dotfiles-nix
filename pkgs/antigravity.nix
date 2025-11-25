{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  xorg,
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
}: let
  pname = "antigravity";
  version = "1.11.5";
in
  stdenv.mkDerivation rec {
    inherit pname version;

    src = fetchurl {
      url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.11.5-5234145629700096/linux-x64/Antigravity.tar.gz";
      hash = "sha256-TgMVGlV0PPMPrFlauzQ8nrWjtqgNJUATbXW06tgHIRI=";
    };

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      xorg.libX11
      xorg.libXext
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
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
    ];

    dontConfigure = true;
    dontBuild = true;

    libPath = lib.makeLibraryPath buildInputs;

    installPhase = ''
      mkdir -p $out/opt/antigravity
      tar -xzf $src -C $out/opt/antigravity --strip-components=1

      # Make the main binary executable
      chmod +x $out/opt/antigravity/antigravity

      # Create a wrapper script to set up the environment
      mkdir -p $out/bin
      makeWrapper $out/opt/antigravity/antigravity $out/bin/antigravity \
        --prefix LD_LIBRARY_PATH : "${libPath}:$out/opt/antigravity"

      # Install the icon
      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp $out/opt/antigravity/resources/app/out/vs/workbench/contrib/antigravityCustomAppIcon/browser/media/antigravity/antigravity.png \
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
