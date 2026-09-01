{
  lib,
  fetchFromGitHub,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "ida-sdk-source";
  version = "9.4";

  src = fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-sdk";
    rev = "v9.4.0-sdk.1";
    hash = "sha256-j6H6CDr26l0RNfbKOzUQBYGzKCQH0m7IX/L1CIjlxvQ=";
    fetchSubmodules = true;
  };

  dontBuild = true;
  dontConfigure = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    cp -r $src/* $out/
    chmod -R u+w $out

    cd $out

    ln -s src/include include
    ln -s src/lib lib
    ln -s src/cmake cmake
    ln -s src/module module

    # Keep compatibility with external CMake projects using the pre-9.4 name.
    ln -s x64_linux_64 $out/src/lib/x64_linux_gcc_64

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open source IDA SDK from HexRaysSA";
    homepage = "https://github.com/HexRaysSA/ida-sdk";
    platforms = platforms.all;
  };
}
