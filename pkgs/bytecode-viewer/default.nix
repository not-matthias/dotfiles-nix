# Run with: nix-build -E '((import <nixpkgs> {}).callPackage (import ./default.nix) { })'
{
  lib,
  stdenv,
  makeWrapper,
  jre,
}:
stdenv.mkDerivation rec {
  pname = "bytecode-viewer";
  version = "2.11.2";
  src = builtins.fetchurl {
    url = "https://github.com/Konloch/bytecode-viewer/releases/download/v${version}/Bytecode-Viewer-${version}.jar";
    sha256 = "sha256-U2rTh0JBBgg/ds0Mt8BRoir/IfCGY7olOcEfHd75FH8=";
  };
  dontUnpack = true;
  nativeBuildInputs = [makeWrapper];
  sourceRoot = ".";
  installPhase = ''
    install -D ${src} "$out/lib/bytecode-viewer.jar"
    mkdir -p "$out/bin"
    makeWrapper "${jre}/bin/java" "$out/bin/bytecode-viewer" \
        --add-flags "-jar $out/lib/bytecode-viewer.jar"
  '';
  meta = with lib; {
    description = "A Java 8+ Jar & Android APK Reverse Engineering Suite (Decompiler, Editor, Debugger & More)";
    homepage = "https://bytecodeviewer.com/";
    sourceProvenance = with sourceTypes; [binaryBytecode];
    license = licenses.gpl3;
    maintainers = with maintainers; [offline];
    platforms = with platforms; unix;
  };
}
