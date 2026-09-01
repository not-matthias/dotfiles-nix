{
  pkgs,
  lib,
  fetchFromGitHub,
  cmake,
  cryptopp,
  ida-sdk-source,
  ...
}:
pkgs.stdenv.mkDerivation rec {
  pname = "ida-hrtng";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "KasperskyLab";
    repo = "hrtng";
    rev = "eb6b9c203a5f3a84c90d982ebf8981683233f231";
    hash = "sha256-zLv0m7eDxWuzzkqs2mfl0lgUJZQpWEv4yQVsER7mgYw=";
    fetchSubmodules = true;
  };

  sourceRoot = "source/src";
  nativeBuildInputs = [cmake];
  buildInputs = [
    cryptopp
    cryptopp.dev
  ];

  NIX_CFLAGS_COMPILE = "-Wno-error -Wno-format-security";

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'add_subdirectory(cryptopp-cmake)' "" \
      --replace-fail 'INCLUDE_DIRECTORIES(''${cryptopp_INCLUDE_DIRS})' 'INCLUDE_DIRECTORIES(''${CRYPTOPP_INCLUDE_DIR})' \
      --replace-fail 'TARGET_LINK_LIBRARIES(hrtng_64 cryptopp)' 'TARGET_LINK_LIBRARIES(hrtng_64 ''${CRYPTOPP_LIBRARY})' \
      --replace-fail 'TARGET_LINK_LIBRARIES(hrtng    cryptopp)' 'TARGET_LINK_LIBRARIES(hrtng    ''${CRYPTOPP_LIBRARY})'
  '';

  cmakeFlags = [
    "-DIDASDK_VER=94"
    "-DIDASDK_DIR=${ida-sdk-source}/src"
    "-DCRYPTOPP_INCLUDE_DIR=${cryptopp.dev}/include"
    "-DCRYPTOPP_LIBRARY=${cryptopp}/lib/libcryptopp.so"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/plugins
    cp hrtng.so $out/plugins/hrtng.so
    cp ${src}/bin/plugins/apilist.txt $out/plugins/
    cp ${src}/bin/plugins/literal.txt $out/plugins/
    runHook postInstall
  '';

  meta = with lib; {
    description = "IDA Pro plugin for decryption, deobfuscation, and pseudocode transformations";
    homepage = "https://github.com/KasperskyLab/hrtng";
    license = licenses.gpl3Only;
    platforms = ["x86_64-linux"];
  };
}
