{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "msty";
  version = "1.0";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://assets.msty.app/Msty_x86_64.AppImage";
    name = "Msty_x86_64.AppImage";
    hash = "sha256-pD+EH/EwmOh2K7bGwg9GtlJBBHuoJnTnu9craFjInRs=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit name src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/msty.desktop -t $out/share/applications
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = {
      license = lib.licenses.agpl3Plus;
      mainProgram = "msty";
      maintainers = with lib.maintainers; [];
      platforms = lib.platforms.linux;
    };
  }
