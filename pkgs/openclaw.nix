{
  appimageTools,
  fetchurl,
  lib,
}: let
  pname = "openclaw";
  version = "2026.9.5";
  src = fetchurl {
    url = "https://github.com/openclaw/openclaw/releases/download/v${version}/OpenClaw-${version}-amd64.AppImage";
    hash = "sha256-pu+PG/0O3S0C7Hpbh4YdRzMo2Hdk9sjdc5ZkxUgy/Jw=";
  };
  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/usr/share/applications/OpenClaw.desktop \
        "$out/share/applications/openclaw.desktop"
      substituteInPlace "$out/share/applications/openclaw.desktop" \
        --replace-fail "Exec=openclaw-desktop" "Exec=$out/bin/openclaw"

      for size in 16x16 32x32 64x64 128x128 256x256 256x256@2 512x512; do
        icon="${appimageContents}/usr/share/icons/hicolor/$size/apps/openclaw-desktop.png"
        [ -f "$icon" ] && install -Dm444 "$icon" \
          "$out/share/icons/hicolor/$size/apps/openclaw.png"
      done
    '';

    meta = {
      description = "OpenClaw Linux companion desktop application";
      homepage = "https://github.com/openclaw/openclaw";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
