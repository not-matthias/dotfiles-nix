{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  makeWrapper,
  openssl,
  wayland,
  libxkbcommon,
  libGL,
  vulkan-loader,
}:
stdenv.mkDerivation rec {
  pname = "tern";
  version = "0.2.2";

  src = requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    url = "https://build.stencil.so/tern";
    hash = "sha256-6/B72qlIFnWjgW2o3cPq/rSoXOXODcG311tKst4K4us=";
  };

  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  buildInputs = [openssl stdenv.cc.cc.lib];
  runtimeDependencies = [
    (lib.getLib wayland)
    (lib.getLib libxkbcommon)
    (lib.getLib libGL)
    (lib.getLib vulkan-loader)
  ];
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/tern"
    cp -r tern assets "$out/libexec/tern/"
    makeWrapper "$out/libexec/tern/tern" "$out/bin/tern"
    runHook postInstall
  '';

  meta = {
    description = "Native terminal with persistent multiplexer sessions";
    homepage = "https://stencil.so/tern";
    license = lib.licenses.unfree;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = ["x86_64-linux"];
    mainProgram = "tern";
  };
}
