{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "lmstudio";
  version = "0.2.27";
  src = fetchurl {
    url = "https://releases.lmstudio.ai/linux/x86/0.2.27/beta/LM_Studio-0.2.27.AppImage";
    hash = "sha256-Mui9QxK7UDnt6cWpYzsoy4hp7P46kx/53+em7Alu1BA=";
  };
in
  appimageTools.wrapType2 {
    inherit pname version src;

    meta = {
      license = lib.licenses.agpl3Plus;
      mainProgram = "lmstudio";
      maintainers = with lib.maintainers; [];
      platforms = lib.platforms.linux;
    };
  }
