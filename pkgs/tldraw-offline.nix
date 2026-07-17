{
  lib,
  appimageTools,
  fetchurl,
  stdenv,
}: let
  pname = "tldraw-offline";
  version = "1.10.0";

  sources = {
    x86_64-linux = {
      suffix = "x86_64";
      hash = "sha256-tIXDzOKjmNpB140kyG+SMVa2H6giPlwRV98IlteAzBE=";
    };
    aarch64-linux = {
      suffix = "arm64";
      hash = "sha256-6AQ8Pyqauxe+HNig5waJPyUadtR11X3II0gN8Q4g9zQ=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
    or (throw "tldraw-offline: unsupported system ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/tldraw/tldraw-offline/releases/download/v${version}/tldraw-offline-linux-${source.suffix}.AppImage";
    inherit (source) hash;
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/@tldesktop.desktop \
        "$out/share/applications/tldraw-offline.desktop"
      substituteInPlace "$out/share/applications/tldraw-offline.desktop" \
        --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=$out/bin/tldraw-offline --no-sandbox %U" \
        --replace-fail "Icon=@tldesktop" "Icon=tldraw-offline"

      install -Dm444 ${appimageContents}/usr/share/icons/hicolor/1024x1024/apps/@tldesktop.png \
        "$out/share/icons/hicolor/1024x1024/apps/tldraw-offline.png"
    '';

    meta = {
      description = "Local, file-based desktop whiteboard built on tldraw's infinite canvas";
      homepage = "https://offline.tldraw.com/";
      # tldraw offline is not open source — all rights reserved.
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "tldraw-offline";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
