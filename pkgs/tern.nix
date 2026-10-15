{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  makeWrapper,
  openssl,
  wayland,
  pipewire,
  libxkbcommon,
  libGL,
  vulkan-loader,
  webkitgtk_4_1,
  glib-networking,
}:
stdenv.mkDerivation rec {
  pname = "tern";
  version = "0.8.3";

  src = requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    url = "https://build.stencil.so/tern";
    hash = "sha256-vMICgHolxxhYVhofV+A95F+94ZE4STAuNKLwo2xs/nk=";
  };

  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  buildInputs = [openssl stdenv.cc.cc.lib];
  runtimeDependencies = [
    (lib.getLib wayland)
    (lib.getLib pipewire)
    (lib.getLib libxkbcommon)
    (lib.getLib libGL)
    (lib.getLib vulkan-loader)
    (lib.getLib webkitgtk_4_1)
  ];
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/tern"
    cp tern "$out/libexec/tern/"
    makeWrapper "$out/libexec/tern/tern" "$out/bin/tern" \
      --prefix GIO_EXTRA_MODULES : "${lib.getLib glib-networking}/lib/gio/modules"
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
