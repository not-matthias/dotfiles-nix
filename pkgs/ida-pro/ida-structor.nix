{
  pkgs,
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  clang,
  python3,
  z3,
  ...
}: let
  inherit (pkgs) stdenv;
  ida-sdk = pkgs.callPackage ./ida-sdk-source.nix {};
in
  stdenv.mkDerivation rec {
    pname = "ida-structor";
    version = "1.0.0";

    src = fetchFromGitHub {
      owner = "19h";
      repo = "ida-structor";
      rev = "46d744d13a4e631ad79385beaf410f0b842b0802";
      hash = "sha256-Wff1GX5/dI/TDUHXtDVZoFFeTiiRnuHTlKEKXG22wCU=";
    };

    nativeBuildInputs = [
      cmake
      ninja
      clang
      python3
    ];

    buildInputs = [
      z3
      z3.dev
      z3.lib
    ];

    postPatch = ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'add_library(z3_custom STATIC IMPORTED GLOBAL)' 'add_library(z3_custom UNKNOWN IMPORTED GLOBAL)' \
        --replace-fail 'elseif(NOT Z3_CUSTOM_LIBRARY MATCHES' 'elseif(FALSE AND NOT Z3_CUSTOM_LIBRARY MATCHES'
    '';

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DIDA_SDK_DIR=${ida-sdk}"
      "-DZ3_USE_CUSTOM=ON"
      "-DZ3_CUSTOM_INCLUDE_DIR=${z3.dev}/include"
      "-DZ3_CUSTOM_LIBRARY=${z3.lib}/lib/libz3.so"
    ];

    preBuild = ''
      export IDA_SDK_DIR=${ida-sdk}
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/plugins
      cp build/structor.so $out/plugins/ 2>/dev/null || true
      runHook postInstall
    '';

    meta = with lib; {
      description = "Structor - Hex-Rays plugin that synthesizes C structures from raw pointer arithmetic";
      homepage = "https://github.com/19h/ida-structor";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
