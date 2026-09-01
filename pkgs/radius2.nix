{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  radare2,
  ...
}:
stdenv.mkDerivation rec {
  pname = "radius2";
  version = "1.2.0";

  src = fetchurl {
    url = "https://github.com/radareorg/radius2/releases/download/${version}/radius2-linux-x86_64";
    hash = "sha256-2TrHqjULsmx6p6eFteFbU3pAcbqyYWSdXvf32QlpPGQ=";
  };
  dontUnpack = true;

  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  dontStrip = true;
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/radius2"
    runHook postInstall
  '';
  postInstall = ''
    wrapProgram $out/bin/radius2 \
      --prefix PATH : ${lib.makeBinPath [radare2]}
  '';

  meta = with lib; {
    description = "Binary emulation and symbolic execution framework using radare2";
    homepage = "https://github.com/radareorg/radius2";
    downloadPage = "https://github.com/radareorg/radius2/releases";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    platforms = ["x86_64-linux"];
    mainProgram = "radius2";
  };
}
