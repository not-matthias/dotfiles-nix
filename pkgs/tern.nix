{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  makeWrapper,
  writeShellScriptBin,
  perf,
  openssl,
  wayland,
  pipewire,
  libxkbcommon,
  libGL,
  vulkan-loader,
  webkitgtk_4_1,
  glib-networking,
  zenity,
}: let
  # Bound perf's per-CPU buffers independently of the host's perf_event_mlock_kb.
  perfMmapPages = 1024;
  profilingPerf = writeShellScriptBin "perf" ''
    if [ "''${1-}" = record ]; then
      shift
      set -- record --mmap-pages=${toString perfMmapPages} "$@"
    fi
    exec ${lib.getExe perf} "$@"
  '';
in
  stdenv.mkDerivation rec {
    pname = "tern";
    version = "0.9.12";

    src = requireFile {
      name = "Tern-${version}-linux-x86_64.tar.gz";
      url = "https://build.stencil.so/tern";
      hash = "sha256-9n6MK/9DfzNlrjpHi7wY9jr7blO9bnzVVrrHziTRNpM=";
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
      # Native close confirmations and file dialogs require a Linux dialog helper.
      makeWrapper "$out/libexec/tern/tern" "$out/bin/tern" \
        --prefix GIO_EXTRA_MODULES : "${lib.getLib glib-networking}/lib/gio/modules" \
        --prefix PATH : "${lib.makeBinPath [profilingPerf zenity]}"
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
