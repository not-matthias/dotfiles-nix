{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  gnutar,
}:
# Prebuilt jcode terminal coding agent. The release tarball ships a small
# launcher shell script alongside the real ELF binary (`*.bin`). The launcher
# only sets LD_LIBRARY_PATH for bundled libs on non-Nix systems; autoPatchelfHook
# patches the binary's RPATH directly, so only the .bin is installed. The tarball
# has no top-level directory, so it is extracted manually in installPhase.
stdenv.mkDerivation rec {
  pname = "jcode";
  version = "0.50.0";

  src = fetchurl {
    url = "https://github.com/1jehuang/jcode/releases/download/v${version}/jcode-linux-x86_64.tar.gz";
    hash = "sha256-bJdtXx1b/01lt1qn82zvJ5QZ4G9a/QH/jzPLTUBZrpA=";
  };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [autoPatchelfHook gnutar];
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    tar xzf $src
    install -Dm755 jcode-linux-x86_64.bin $out/bin/jcode
    runHook postInstall
  '';

  meta = {
    description = "Open-source terminal coding agent (jcode)";
    homepage = "https://github.com/1jehuang/jcode";
    downloadPage = "https://github.com/1jehuang/jcode/releases";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "jcode";
  };
}
