{
  pkgs,
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  clang,
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
      rev = "master";
      hash = "sha256-Zx1Rbwny7KFOoWDYyjCkH8MtGIs5wLFVrfTH3531B4I=";
    };

    nativeBuildInputs = [
      cmake
      ninja
      clang
      z3
    ];

    buildInputs = [
      z3
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DIDA_SDK_DIR=${ida-sdk}"
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
