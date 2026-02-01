{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "handy";
  version = "0.7.0";
  src = fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.AppImage";
    hash = "sha256-tTswFYLCPGtMbHAb2bQMsklRiRCVXLrtu4pQC8IHdqQ=";
  };
in
  appimageTools.wrapType2 {
    inherit pname version src;

    meta = {
      description = "A simple hand-tracking application";
      homepage = "https://github.com/cjpais/Handy";
      license = lib.licenses.mit;
      mainProgram = "handy";
      maintainers = with lib.maintainers; [];
      platforms = lib.platforms.linux;
    };
  }
