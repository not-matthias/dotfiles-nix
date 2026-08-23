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
  z3-src = fetchFromGitHub {
    owner = "Z3Prover";
    repo = "z3";
    rev = "745087e237e669d709ae35694728a0c479e572b3";
    hash = "sha256-eyF3ELv81xEgh9Km0Ehwos87e4VJ82cfsp53RCAtuTo=";
  };
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
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DIDA_SDK_DIR=${ida-sdk}"
      "-DFETCHCONTENT_SOURCE_DIR_Z3=${z3-src}"
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
