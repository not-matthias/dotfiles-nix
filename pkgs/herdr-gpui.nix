{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  alsa-lib,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
}: let
  version = "20261007.3";
  assets = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-u2jhLLPZRQSpy8ZbReys+tc+IkFX2Gc+FnY3RNPy43A=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-laHf0h1GP4K2NcJYNEEMUoFQuHDJkd0zTqwlVwwCl/8=";
    };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "Herdr GPUI ${version} is not available for ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "herdr-gpui";
    inherit version;

    src = fetchurl {
      url = "https://github.com/penso/herdr-gpui/releases/download/v${version}/Herdr-${version}-${asset.target}.tar.gz";
      inherit (asset) hash;
    };

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [alsa-lib libxcb libxkbcommon stdenv.cc.cc.lib];
    # GPUI loads the rendering and display backends with dlopen.
    runtimeDependencies = [
      (lib.getLib vulkan-loader)
      (lib.getLib wayland)
    ];
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/herdr-gpui "$out/bin/herdr-gpui"
      mkdir -p "$out/share"
      cp -r share/icons share/licenses "$out/share/"
      runHook postInstall
    '';

    meta = {
      description = "Native GPUI client for an existing local Herdr daemon";
      homepage = "https://github.com/penso/herdr-gpui";
      downloadPage = "https://github.com/penso/herdr-gpui/releases";
      license = lib.licenses.asl20;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames assets;
      mainProgram = "herdr-gpui";
    };
  }
