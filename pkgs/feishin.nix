{
  lib,
  appimageTools,
  fetchurl,
  stdenv,
}: let
  pname = "feishin";
  version = "0.19.0";

  sources = {
    x86_64-linux = {
      url = "https://github.com/jeffvli/feishin/releases/download/v${version}/Feishin-linux-x86_64.AppImage";
      hash = "sha256-oTOzzZxv63W1GZynwqsQj0fb/tOXfbD4KLCvz9aq12w=";
    };
    aarch64-linux = {
      url = "https://github.com/jeffvli/feishin/releases/download/v${version}/Feishin-linux-arm64.AppImage";
      hash = lib.fakeHash; # Replace with actual hash after first build attempt
    };
  };

  src = fetchurl {
    inherit (sources.${stdenv.hostPlatform.system}) url hash;
    name = "Feishin-${stdenv.hostPlatform.system}.AppImage";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/feishin.desktop -t $out/share/applications
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = with lib; {
      description = "A modern self-hosted music player";
      homepage = "https://github.com/jeffvli/feishin";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [];
      platforms = platforms.linux;
      mainProgram = "feishin";
    };
  }
