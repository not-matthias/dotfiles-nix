{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kache";
  version = "2.3.1";

  src = fetchurl {
    url = "https://github.com/kunobi-ninja/kache/releases/download/v${version}/kache-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-bx/z+fr1qbsOOFAcW/6atbSpgINPHINdCa1bD9+bark=";
  };

  dontUnpack = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    tar xzf "$src" kache kache-engine kache-cl kache-clang-cl
    install -Dm755 -t "$out/bin" kache kache-engine kache-cl kache-clang-cl
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
