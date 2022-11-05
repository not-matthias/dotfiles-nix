# https://github.com/nix-community/nur-combined/blob/master/repos/htr/pkgs/idafree/default.nix
# Run with: nix-build -E 'with import <nixpkgs> { }; pkgs.libsForQt5.callPackage ./default.nix {}'
{
  pkgs,
  qtbase,
  stdenv,
  wrapQtAppsHook,
  ...
}: let
  installer = pkgs.fetchurl {
    url = "https://out7.hex-rays.com/files/idafree81_linux.run";
    sha256 = "4QRXQY94Ga0LWzV4s8gSX29D1gkvxJqoco+IyXcS8BU=";
    executable = true;
  };

  idaWrapper = pkgs.buildFHSUserEnv rec {
    name = "ida-wrapper";
    multiPkgs = pkgs:
      with pkgs; [
        libGL
        zlib
        glib
        freetype
        dbus
        fontconfig
        # xorg.libXinerama
        # xorg.libXdamage
        # xorg.libXcursor
        # xorg.libXrender
        # xorg.libXScrnSaver
        # xorg.libXxf86vm
        # xorg.libXi
        xorg.libSM
        xorg.libICE
        # xorg.libXt
        # xorg.libXmu
        # xorg.libXcomposite
        # xorg.libXtst
        # xorg.libXrandr
        # xorg.libXext
        xorg.libX11
        # xorg.libXfixes
        # xorg.xkeyboardconfig
        xorg.libxcb
        xorg.xcbutil
        xorg.xcbproto
        xorg.xcbutilwm
        xorg.xcbutilimage
        xorg.xcbutilerrors
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        libxkbcommon
      ];
    runScript = pkgs.writeScript "ida-wrapper" ''
      exec -- "$@"
    '';
  };
in
  stdenv.mkDerivation {
    pname = "ida";
    version = "6.7.1";
    unpackPhase = "true";
    sourceRoot = ".";

    # We want to run wrapProgram manually (with additional parameters)
    dontWrapGApps = true;
    dontWrapQtApps = true;

    nativeBuildInputs = with pkgs; [
      wrapGAppsHook
      wrapQtAppsHook
    ];

    # QT_QPA_PLATFORM_PLUGIN_PATH="${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins";
    buildInputs = [
      qtbase
      # pkgs.qt5.full
    ];
    installPhase = ''
      mkdir -p $out/bin $out/opt

      cat <<EOF > $out/bin/idafree
      #!/bin/sh
      cd $out/opt
      exec ${idaWrapper}/bin/ida-wrapper ./ida64
      EOF
      chmod +x $out/bin/idafree

      ${idaWrapper}/bin/ida-wrapper ${installer} --prefix $out/opt  --mode unattended --installpassword x
    '';
  }
