{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  libGL,
  glib,
  xorg,
  fontconfig,
  freetype,
  dbus,
}: let
  pname = "vmprotect";
  version = "demo";
in
  stdenv.mkDerivation rec {
    inherit pname version;

    src = fetchurl {
      url = "https://vmpsoft.com/uploads/VMProtectDemo.tar.gz";
      hash = "sha256-SEZmzNkvZVW5U4vWy4X6axXix/r1j7lH8ZMwqHSZfBg=";
      curlOptsList = ["--insecure"]; # SSL certificate issue on vmpsoft.com
    };

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      stdenv.cc.cc.lib # libstdc++
      zlib
      libGL
      glib
      xorg.libX11
      xorg.libXext
      xorg.libxcb
      xorg.libXi
      xorg.libSM
      xorg.libICE
      xorg.libXrender
      fontconfig
      freetype
      dbus
    ];

    # Tarball has files at root level without a top-level directory
    sourceRoot = ".";

    # Ignore Android library dependencies (we only need Linux binaries)
    autoPatchelfIgnoreMissingDeps = ["liblog.so"];

    dontConfigure = true;
    dontBuild = true;

    libPath = lib.makeLibraryPath buildInputs;

    installPhase = ''
            runHook preInstall

            mkdir -p $out/opt/vmprotect
            cp -r . $out/opt/vmprotect

            # Make binaries executable
            chmod +x $out/opt/vmprotect/vmprotect_gui
            chmod +x $out/opt/vmprotect/vmprotect_con

            # Create wrapper scripts with proper library paths
            mkdir -p $out/bin

            # Wrapper for GUI version
            makeWrapper $out/opt/vmprotect/vmprotect_gui $out/bin/vmprotect \
              --prefix LD_LIBRARY_PATH : "${libPath}:$out/opt/vmprotect" \
              --set QT_PLUGIN_PATH "$out/opt/vmprotect/PlugIns" \
              --set QT_QPA_PLATFORM "xcb" \
              --set QT_AUTO_SCREEN_SCALE_FACTOR "1" \
              --set QT_ENABLE_HIGHDPI_SCALING "1"

            # Wrapper for console version
            makeWrapper $out/opt/vmprotect/vmprotect_con $out/bin/vmprotect-console \
              --prefix LD_LIBRARY_PATH : "${libPath}:$out/opt/vmprotect"

            # Create desktop entry for GUI version
            mkdir -p $out/share/applications
            cat > $out/share/applications/vmprotect.desktop <<EOF
      [Desktop Entry]
      Name=VMProtect
      Comment=Software protection and licensing tool
      Exec=$out/bin/vmprotect
      Type=Application
      Categories=Development;
      Terminal=false
      StartupNotify=true
      EOF

            runHook postInstall
    '';

    meta = {
      description = "VMProtect Demo - software protection and licensing tool";
      homepage = "https://vmpsoft.com";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "vmprotect";
    };
  }
