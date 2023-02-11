# https://github.com/nix-community/nur-combined/blob/master/repos/htr/pkgs/idafree/default.nix
# Run with: nix-build -E 'with import <nixpkgs> { }; pkgs.libsForQt5.callPackage ./default.nix {}'
{
  pkgs,
  lib,
  qtbase,
  stdenv,
  wrapQtAppsHook,
  makeDesktopItem,
  ...
}: let
  installer = pkgs.fetchurl {
    url = "https://out7.hex-rays.com/files/idafree82_linux.run";
    sha256 = "sha256-BNVdggVBbKyVy6SKVTCoVjuybNh7YaNmKRQuHin/NmA=";
    executable = true;
  };

  idaWrapper = pkgs.buildFHSUserEnv rec {
    name = "ida-wrapper";
    multiPkgs = pkgs:
      with pkgs; [
        atk
        openssl # required for libcrypto.so
        #        libsecret
        zlib
        libGL
        glib
        gtk3
        gtk2
        glib
        cairo
        pango
        libdrm
        gdk-pixbuf
        freetype
        dbus
        fontconfig
        xorg.libSM
        xorg.libICE
        xorg.libX11
        xorg.libxcb
        xorg.xcbutil
        xorg.xcbproto
        xorg.xcbutilwm
        xorg.xcbutilimage
        xorg.xcbutilerrors
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        libxkbcommon
        # Other libs which might not be needed
        xorg.libXinerama
        xorg.libXdamage
        xorg.libXcursor
        xorg.libXrender
        xorg.libXScrnSaver
        xorg.libXxf86vm
        xorg.libXi
        xorg.libXt
        xorg.libXmu
        xorg.libXcomposite
        xorg.libXtst
        xorg.libXrandr
        xorg.libXext
        xorg.libXfixes
        xorg.xkeyboardconfig
      ];
    runScript = pkgs.writeScript "ida-wrapper" ''
      exec -- "$@"
    '';
  };

  desktopItem = makeDesktopItem {
    name = "idafree";
    exec = "idafree";
    icon = "idafree";
    genericName = "IDA Free";
    desktopName = "IDA Free";
    categories = ["Development" "IDE"];
  };
in
  stdenv.mkDerivation {
    pname = "idafree";
    version = "8.2";
    system = builtins.currentSystem;

    nativeBuildInputs = with pkgs; [
      wrapQtAppsHook
    ];
    buildInputs = [qtbase];

    unpackPhase = ''
      mkdir -p $out/bin $out/opt

      cat <<EOF > $out/bin/idafree
      #!/bin/sh
      cd $out/opt
      LD_PRELOAD=${pkgs.libsecret}/lib/libsecret-1.so.0 exec ${idaWrapper}/bin/ida-wrapper ./ida64
      EOF
      chmod +x $out/bin/idafree

      ${idaWrapper}/bin/ida-wrapper ${installer} --prefix $out/opt  --mode unattended --installpassword x
    '';

    installPhase = ''
      mkdir -p $out/share/{applications,icons}

      ln -s ${desktopItem}/share/applications/* $out/share/applications/
      ln -s $out/opt/appico64.png $out/share/icons/idafree.png

      # for i in 16 32 48 128; do
      #   mkdir -p $out/share/icons/hicolor/''${i}x''${i}/apps
      #   ln -s $out/opt/appico64.png $out/share/icons/hicolor/''${i}x''${i}/apps/idafree.png
      # done
    '';

    meta = with lib; {
      description = "The free binary code analysis tool to kickstart your reverse engineering experience.";
      homepage = "https://hex-rays.com/ida-free/";
      license = licenses.unfree;
      platforms = platforms.linux;
      # maintainers = with maintainers; [tgunnoe];
    };
  }
