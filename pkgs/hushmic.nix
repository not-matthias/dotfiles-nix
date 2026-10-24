{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  pipewire,
  libGL,
  libxkbcommon,
  wayland,
  libX11,
  libXcursor,
  libXi,
  libXrandr,
  libxcb,
}: let
  version = "0.8.1";

  guiLibs = [
    libGL
    libxkbcommon
    wayland
    libX11
    libXcursor
    libXi
    libXrandr
    libxcb
  ];
in
  stdenv.mkDerivation {
    pname = "hushmic";
    inherit version;

    src = fetchurl {
      url = "https://github.com/Fovty/HushMic/releases/download/v${version}/hushmic-${version}-x86_64.tar.gz";
      hash = "sha256-NnJ02BDD5w5Dv5+IpneRW9/sKaq5/ETjb0gvfMa9jrI=";
    };
    sourceRoot = "hushmic-${version}-x86_64";

    dontBuild = true;
    dontConfigure = true;
    dontStrip = true;

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];
    buildInputs = [stdenv.cc.cc.lib] ++ guiLibs;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin" "$out/libexec" "$out/lib" "$out/share/licenses/hushmic"
      install -Dm755 bin/hushmic "$out/libexec/hushmic"
      cp -a lib/hushmic "$out/lib/"
      cp -a lib/ladspa "$out/lib/"
      cp -a share/. "$out/share/"
      install -Dm644 LICENSE-MIT "$out/share/licenses/hushmic/LICENSE-MIT"
      install -Dm644 LICENSE-APACHE "$out/share/licenses/hushmic/LICENSE-APACHE"

      makeWrapper "$out/libexec/hushmic" "$out/bin/hushmic" \
        --prefix PATH : ${lib.makeBinPath [pipewire]} \
        --prefix LD_LIBRARY_PATH : "$out/lib/hushmic:${lib.makeLibraryPath guiLibs}" \
        --set HUSHMIC_PLUGIN_SO "$out/lib/ladspa/libdpdfnet_ladspa.so" \
        --set HUSHMIC_MODEL_DIR "$out/share/hushmic/models" \
        --set ORT_DYLIB_PATH "$out/lib/hushmic/libonnxruntime.so" \
        --set HUSHMIC_TRAY_THEME_DIR "$out/share/icons"
      runHook postInstall
    '';

    meta = {
      description = "Real-time microphone noise suppression as a virtual mic";
      homepage = "https://github.com/Fovty/hushmic";
      license = with lib.licenses; [
        mit
        asl20
      ];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      mainProgram = "hushmic";
      platforms = ["x86_64-linux"];
    };
  }
