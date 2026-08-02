{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "binja-wasm";
  version = "0.1.1";

  src = fetchurl {
    url = "https://github.com/chadhyatt/binja-wasm/releases/download/${version}/binja-wasm-${version}-linux-x86_64.tar.gz";
    hash = "sha256-unDUSo68HMokrf6cy+xyTBXs5I/tw3YQdy4KrlDByWU=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib];

  # libbinaryninjacore.so.1 ships only inside the licensed Binary Ninja install,
  # which resolves it via LD_LIBRARY_PATH when the plugin is dlopen'd.
  autoPatchelfIgnoreMissingDeps = ["libbinaryninjacore.so.1"];

  # Only the library belongs in the plugins directory: Binary Ninja dlopens every
  # library it finds there, and that directory is shared by all extensions, so any
  # generically-named metadata file would collide between plugins.
  installPhase = ''
    runHook preInstall
    install -Dm755 libbinja_wasm.so $out/lib/binaryninja/plugins/libbinja_wasm.so
    install -Dm644 plugin.json $out/share/doc/binja-wasm/plugin.json
    install -Dm644 LICENSE $out/share/doc/binja-wasm/LICENSE
    runHook postInstall
  '';

  meta = {
    description = "WebAssembly architecture and binary view plugin for Binary Ninja";
    longDescription = ''
      The upstream release is built against Binary Ninja 5.3.9757 and requires
      a compatible Binary Ninja core ABI.
    '';
    homepage = "https://github.com/chadhyatt/binja-wasm";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
  };
}
