{
  appimageTools,
  fetchurl,
  graphicsmagick,
  lib,
  makeWrapper,
  stdenv,
  rocmVendorPath ? null,
}: let
  pname = "lmstudio";
  version = "0.4.24-1";
  src = fetchurl {
    url = "https://installers.lmstudio.ai/linux/x64/${version}/LM-Studio-${version}-x64.AppImage";
    hash = "sha256-F8uKxjdPkYL8En764gaAJl48TBfZbq3xR+tf5hEak1M=";
  };
  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    nativeBuildInputs = [
      graphicsmagick
      makeWrapper
    ];
    extraPkgs = pkgs: [pkgs.ocl-icd];

    extraInstallCommands = ''
      mkdir -p $out/share/applications

      src_icon="${appimageContents}/usr/share/icons/hicolor/512x512/apps/lm-studio.png"
      sizes=("16x16" "32x32" "48x48" "64x64" "128x128" "256x256")
      for size in "''${sizes[@]}"; do
        install -dm755 "$out/share/icons/hicolor/$size/apps"
        gm convert "$src_icon" -resize "$size" "$out/share/icons/hicolor/$size/apps/lm-studio.png"
      done

      install -m 444 -D ${appimageContents}/ai.elementlabs.lmstudio.desktop \
        "$out/share/applications/lm-studio.desktop"
      mv $out/bin/lmstudio $out/bin/lm-studio

      substituteInPlace $out/share/applications/lm-studio.desktop \
        --replace-fail 'Exec=AppRun %U' 'Exec=lm-studio %U'
      ${lib.optionalString (rocmVendorPath != null) ''
        wrapProgram $out/bin/lm-studio \
          --run 'export LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib:$HOME/${rocmVendorPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"'
      ''}

      install -m 755 ${appimageContents}/resources/app/.webpack/lms $out/bin/
      patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" $out/bin/lms
    '';

    meta = {
      description = "LM Studio is an easy to use desktop app for experimenting with local and open-source Large Language Models";
      homepage = "https://lmstudio.ai/";
      license = lib.licenses.unfree;
      mainProgram = "lm-studio";
      platforms = ["x86_64-linux"];
    };
  }
