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
        atk
        openssl # required for libcrypto.so
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
in
  stdenv.mkDerivation {
    pname = "idafree";
    version = "8.1";
    unpackPhase = "true";

    nativeBuildInputs = with pkgs; [
      wrapQtAppsHook
    ];
    buildInputs = [qtbase];

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
