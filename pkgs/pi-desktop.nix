{
  lib,
  appimageTools,
  fetchurl,
  mesa,
}: let
  pname = "pi-desktop";
  version = "0.1.9";
  src = fetchurl {
    url = "https://github.com/gustavonline/pi-desktop/releases/download/v${version}/Pi.Desktop_${version}_amd64.AppImage";
    hash = "sha256-FJ6lDHEUc8uR6HoNqMzre0kyHmpv7V2x0gcOkEwOG24=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      # The bundled GTK hook forces GDK_BACKEND=x11 which crashes on Wayland-only
      # compositors (e.g. niri). Remove the forced backend so it auto-detects.
      sed -i 's/^export GDK_BACKEND=x11/#export GDK_BACKEND=x11/' \
        $out/apprun-hooks/linuxdeploy-plugin-gtk.sh
    '';
  };
in
  appimageTools.wrapAppImage {
    inherit pname version;
    src = appimageContents;

    # mesa provides the EGL vendor JSON and DRI drivers needed for GPU rendering
    extraPkgs = _pkgs: [mesa];

    extraInstallCommands = ''
      install -m 444 -D "${appimageContents}/Pi Desktop.desktop" -t $out/share/applications
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = {
      description = "Desktop shell for the Pi coding agent";
      homepage = "https://github.com/gustavonline/pi-desktop";
      license = lib.licenses.mit;
      mainProgram = "pi-desktop";
      platforms = ["x86_64-linux"];
    };
  }
