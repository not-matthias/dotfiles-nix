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
  version = "0.2.6";

  src = requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    url = "https://build.stencil.so/d/tern/20261001-202121-0e1ce50/Tern-${version}-linux-x86_64.tar.gz";
    hash = "sha256-ixVSy3r9AdyZOgT93e0RkAVXB1eJST5euOb64rb5do4=";
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
