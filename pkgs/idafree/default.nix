# Run with: nix-build -E 'with import <nixpkgs> { }; pkgs.libsForQt5.callPackage ./default.nix {}'
# References:
# - https://github.com/nix-community/nur-combined/blob/master/repos/htr/pkgs/idafree/default.nix
# - https://cs.github.com/marenz2569/nix-configs/blob/f8f8bc8a03b391f2b7fd8d269c3d69ef19c56adb/overlays/ida-free/default.nix?q=idafree+language%3Anix
{
  stdenv,
  lib,
  dbus,
  autoPatchelfHook,
  xorg,
  libGL,
  libxkbcommon,
  libglibutil,
  cairo,
  libdrm,
  pango,
  gdk-pixbuf,
  gtk3,
  krb5,
  libsForQt5,
  pkgs,
  makeDesktopItem,
}: let
  pname = "idafree";
  version = "82";

  binary = "${pname}${version}_linux.run";

  installer = stdenv.mkDerivation rec {
    inherit version;

    pname = "idafree-installer";

    src = builtins.fetchurl {
      url = "https://out7.hex-rays.com/files/${binary}";
      sha256 = "sha256:17rbdfpq8al6vc2gp42g91asswzfnmy8j420b5n9a57xrpq9pk55";
    };

    phases = ["installPhase"];

    installPhase = ''
      mkdir -p $out/bin/
      cp $src $out/bin/${binary}
      chmod +wx $out/bin/${binary}
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$out/bin/${binary}"
    '';
  };
in
  stdenv.mkDerivation rec {
    inherit pname;
    inherit version;

    src = installer;

    nativeBuildInputs = [autoPatchelfHook libsForQt5.qt5.wrapQtAppsHook];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      dbus
      xorg.libxcb
      xorg.libX11
      xorg.libSM
      xorg.libICE
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilrenderutil
      xorg.xcbutilwm
      libGL
      libxkbcommon
      libglibutil
      cairo
      libdrm
      pango
      gdk-pixbuf
      gtk3
      krb5
      libsecret
      libsForQt5.qt5.qtbase
      openssl # required for libcrypto.so
    ];

    desktopItem = makeDesktopItem {
      name = "idafree";
      exec = "idafree";
      icon = "idafree";
      genericName = "IDA Free";
      desktopName = "IDA Free";
      categories = ["Development" "IDE"];
    };
    installPhase = ''
      mkdir -p $out/bin
      $src/bin/${binary} --prefix $out --mode unattended

      mkdir -p $out/share/{applications,icons}
      ln -s ${desktopItem}/share/applications/* $out/share/applications/
      ln -s $out/opt/appico64.png $out/share/icons/idafree.png
    '';

    postFixup = ''
      ln -s $out/ida64 $out/bin/idafree
    '';

    meta = with lib; {
      description = "IDA Freeware - The free binary code analysis tool to kickstart your reverse engineering experience.";
      homepage = "https://hex-rays.com/ida-free/";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
    };
  }
