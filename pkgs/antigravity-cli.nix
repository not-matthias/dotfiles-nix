{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  patchelf,
  makeWrapper,
}:
stdenvNoCC.mkDerivation {
  pname = "antigravity-cli";
  version = "1.5.9";
  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.9-4515810895593472/linux-x64/cli_linux_x64.tar.gz";
    hash = "sha256-ix9eVnefJDSgrzbxtxWoOSoITeVQ+MaLx5gh+V+r8/o=";
  };
  dontUnpack = true;
  dontStrip = true;
  dontPatchELF = true;
  nativeBuildInputs = [patchelf makeWrapper];
  installPhase = ''
    runHook preInstall
    tar -xzf $src
    install -Dm755 antigravity $out/libexec/agy
    patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" $out/libexec/agy
    makeWrapper $out/libexec/agy $out/bin/agy \
      --set AGY_CLI_DISABLE_AUTO_UPDATE true
    runHook postInstall
  '';
  meta = {
    description = "Official Antigravity command-line agent";
    homepage = "https://antigravity.google/docs/cli/";
    license = lib.licenses.unfree;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = ["x86_64-linux"];
    mainProgram = "agy";
  };
}
