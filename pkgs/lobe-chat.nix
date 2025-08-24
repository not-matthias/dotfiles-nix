{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "lobe-chat";
  version = "1.114.0";
  src = fetchurl {
    url = "https://github.com/lobehub/lobe-chat/releases/download/v${version}/LobeHub-Beta-${version}.AppImage";
    sha256 = "sha256-kUwZYBj+bFl//iNjwLeoFXDM8LAXCIgpKOL7/e4LV/8=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/lobehub-desktop-beta.desktop -t $out/share/applications
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = {
      description = "🤯 Lobe Chat - an open-source, modern-design ChatGPT/LLMs UI/Framework";
      homepage = "https://github.com/lobehub/lobe-chat";
      license = lib.licenses.mit;
      mainProgram = "lobehub-desktop-beta";
      maintainers = with lib.maintainers; [];
      platforms = lib.platforms.linux;
    };
  }
