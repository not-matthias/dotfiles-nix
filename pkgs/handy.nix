{
  lib,
  appimageTools,
  fetchurl,
  stdenv,
  wtype,
  xdotool,
}: let
  pname = "handy";
  version = "0.8.3";

  sources = {
    x86_64-linux = {
      suffix = "amd64";
      hash = "sha256-8rQJVpABydLXGlyLNIdw/cilAcmwvmAb93VoaJJ+KJQ=";
    };
    aarch64-linux = {
      suffix = "aarch64";
      hash = "sha256-CgSlTk3mJN/o1NuKeRKt7f+iRHPBqMUAhKhHDVBQNTE=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
    or (throw "handy: unsupported system ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_${source.suffix}.AppImage";
    inherit (source) hash;
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = _pkgs: [wtype xdotool];

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/usr/share/applications/Handy.desktop \
        "$out/share/applications/handy.desktop"
      substituteInPlace "$out/share/applications/handy.desktop" \
        --replace-fail "Exec=handy" "Exec=$out/bin/handy"

      for size in 32x32 128x128 256x256@2; do
        icon="${appimageContents}/usr/share/icons/hicolor/$size/apps/handy.png"
        [ -f "$icon" ] && install -Dm444 "$icon" \
          "$out/share/icons/hicolor/$size/apps/handy.png"
      done
    '';

    meta = {
      description = "A free, open source, and extensible speech-to-text application that works completely offline";
      homepage = "https://handy.computer/";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "handy";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
