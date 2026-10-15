{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "knife";
  version = "1.8.3";

  src = fetchurl {
    url = "https://github.com/bl4ckr0ss3/knife/releases/download/v${version}/knife-x86_64-unknown-linux-gnu.tgz";
    hash = "sha256-XI3Uz18Ul3Qouu4qOn5r8LX1i2jm2DcjAnZZd5R0AIk=";
  };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    tar xzf "$src"
    install -Dm755 knife "$out/bin/knife"
    install -Dm644 LICENSE "$out/share/licenses/knife/LICENSE"
    install -Dm644 README.md "$out/share/doc/knife/README.md"
    runHook postInstall
  '';

  meta = {
    description = "Terminal-first reverse engineering toolkit for PE, ELF, Mach-O, and WebAssembly";
    homepage = "https://github.com/bl4ckr0ss3/knife";
    license = lib.licenses.mit;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = ["x86_64-linux"];
    mainProgram = "knife";
  };
}
