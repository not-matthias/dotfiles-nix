{
  lib,
  fetchFromGitHub,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "ida-sdk-source";
  version = "9.3";

  src = fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-sdk";
    rev = "v${version}";
    hash = "sha256-saL163WsoYZ/tub+7Ds0pW4MWOI/GvOrOCTCE0tVauw=";
    fetchSubmodules = true;
  };

  dontBuild = true;
  dontConfigure = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    cp -r $src/* $out/

    cd $out

    ln -s src/include include
    ln -s src/lib lib
    ln -s src/cmake cmake
    ln -s src/module module

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open source IDA SDK from HexRaysSA";
    homepage = "https://github.com/HexRaysSA/ida-sdk";
    platforms = platforms.all;
  };
}
