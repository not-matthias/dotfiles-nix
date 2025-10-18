{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "handy";
  version = "0.5.3";
  src = fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.AppImage";
    hash = "sha256-A6d/EijWXSZvxibNXa6/oiFQqTG5+dp8z6i2Xr4awtk=";
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
