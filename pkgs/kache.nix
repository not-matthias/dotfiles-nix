{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kache";
  version = "1.2.2";

  src = fetchurl {
    url = "https://github.com/kunobi-ninja/kache/releases/download/v${version}/kache-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-8vZVXe5QlFwqkKf7eTwghKAMxkWdCKwjBtONkFBkMhs=";
  };

  dontUnpack = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    tar xzf "$src" kache
    install -Dm755 kache "$out/bin/kache"
    runHook postInstall
  '';

  meta = {
    description = "Compiler cache for Rust, C/C++ and CUDA";
    homepage = "https://github.com/kunobi-ninja/kache";
    license = lib.licenses.asl20;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = ["x86_64-linux"];
    mainProgram = "kache";
  };
}
