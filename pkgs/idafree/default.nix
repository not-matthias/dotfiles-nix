# https://github.com/nix-community/nur-combined/blob/master/repos/htr/pkgs/idafree/default.nix
# Run with: nix-build -E 'with import <nixpkgs> { }; pkgs.libsForQt5.callPackage ./default.nix {}'      
{
  pkgs ? import <nixpkgs> {},
  qtbase,
  wrapQtAppsHook,
  ...
}: let
  idafree-installer-package = pkgs.fetchurl {
    url = "https://out7.hex-rays.com/files/idafree81_linux.run";
    sha256 = "4QRXQY94Ga0LWzV4s8gSX29D1gkvxJqoco+IyXcS8BU=";
    executable = true;
  };
  fhsIDAWrapper = pkgs.buildFHSUserEnv rec {
    name = "fhs-ida-wrapper";

    multiPkgs = pkgs:
      with pkgs; [
        qtbase
        wrapQtAppsHook
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
      ];
    runScript = pkgs.writeScript "fhs-ida-wrapper" ''
      exec -- "$@"
    '';
  };
in
  pkgs.stdenv.mkDerivation {
    name = "idafree-bin";
    unpackPhase = "true";

    buildInputs = [qtbase];
    nativeBuildInputs = [wrapQtAppsHook];
    installPhase = ''
      mkdir -p $out/bin $out/opt
      cat <<EOF > $out/bin/idafree
      #!/bin/sh
      cd $out/opt
      exec ${fhsIDAWrapper}/bin/fhs-ida-wrapper ./ida64
      EOF
      chmod +x $out/bin/idafree
      ${fhsIDAWrapper}/bin/fhs-ida-wrapper ${idafree-installer-package} --prefix $out/opt  --mode unattended --installpassword x
    '';
  }
