{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  makeWrapper,
  patchelf,
  pkg-config,
  onnxruntime,
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
  model8 = fetchurl {
    url = "https://huggingface.co/Ceva-IP/DPDFNet/resolve/main/onnx/dpdfnet8_48khz_hr.onnx?download=true";
    hash = "sha256-ezr7smCgj+mvPRbjvamSlxvh5+lR0d7nwtI19cQ/VjE=";
  };
  model2 = fetchurl {
    url = "https://huggingface.co/Ceva-IP/DPDFNet/resolve/main/onnx/dpdfnet2_48khz_hr.onnx?download=true";
    hash = "sha256-fwV1pc7Auk/9j4vWV+BtAH5MzdlV12+quSK50ykdwUs=";
  };
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
  rustPlatform.buildRustPackage rec {
    pname = "hushmic";
    version = "0.8.1";

    src = fetchFromGitHub {
      owner = "Fovty";
      repo = "hushmic";
      tag = "v${version}";
      hash = "sha256-Xco66VfBH2ZGJGyfR+Pbvfv3p3vWCKL7UguH9GnS2/g=";
    };

    cargoHash = "sha256-UijVgQLaxN05VA1WVMoKrUQ4ov093vUw5D/eWm98B84=";

    nativeBuildInputs = [
      makeWrapper
      patchelf
      pkg-config
    ];
    buildInputs = [onnxruntime] ++ guiLibs;

    HUSHMIC_BUILD_MODEL = "${placeholder "out"}/share/hushmic/models/dpdfnet8_48khz_hr.onnx";
    HUSHMIC_BUILD_DYLIB = "${onnxruntime}/lib/libonnxruntime.so";

    preCheck = ''
      mkdir -p "$out/share/hushmic/models"
      ln -s ${model8} "$out/share/hushmic/models/dpdfnet8_48khz_hr.onnx"
    '';

    postInstall = ''
      install -Dm644 "$(find target -path '*/release/libdpdfnet_ladspa.so' -print -quit)" \
        "$out/lib/ladspa/libdpdfnet_ladspa.so"
      rm -f "$out/lib/libdpdfnet_ladspa.so"
      rm -f "$out/share/hushmic/models/dpdfnet8_48khz_hr.onnx"
      install -Dm644 ${model8} "$out/share/hushmic/models/dpdfnet8_48khz_hr.onnx"
      install -Dm644 ${model2} "$out/share/hushmic/models/dpdfnet2_48khz_hr.onnx"
      install -Dm644 packaging/hushmic.desktop "$out/share/applications/hushmic.desktop"
      install -Dm644 packaging/hushmic-256.png "$out/share/icons/hicolor/256x256/apps/hushmic.png"

      for size in 16x16 22x22 24x24 32x32 48x48 64x64 128x128 256x256; do
        for icon in hushmic-tray hushmic-tray-off hushmic-tray-bypass hushmic-tray-mute hushmic-tray-error; do
          install -Dm644 "packaging/tray/hicolor/$size/status/$icon.png" \
            "$out/share/icons/hicolor/$size/status/$icon.png"
        done
      done

      wrapProgram "$out/bin/hushmic" \
        --prefix PATH : ${lib.makeBinPath [pipewire]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath guiLibs} \
        --set HUSHMIC_PLUGIN_SO "$out/lib/ladspa/libdpdfnet_ladspa.so" \
        --set HUSHMIC_MODEL_DIR "$out/share/hushmic/models" \
        --set ORT_DYLIB_PATH "${onnxruntime}/lib/libonnxruntime.so" \
        --set HUSHMIC_TRAY_THEME_DIR "$out/share/icons";
    '';

    postFixup = ''
      patchelf --add-rpath "${lib.makeLibraryPath guiLibs}" "$out/bin/.hushmic-wrapped"
    '';

    meta = {
      description = "Real-time microphone noise suppression as a virtual mic";
      homepage = "https://github.com/Fovty/hushmic";
      license = with lib.licenses; [
        mit
        asl20
      ];
      mainProgram = "hushmic";
      platforms = ["x86_64-linux"];
    };
  }
