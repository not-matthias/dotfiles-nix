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
    version = "2.2.0";

    src = fetchFromGitHub {
      owner = "19h";
      repo = "ida-structor";
      rev = "v${version}";
      hash = "sha256-71CmDRqmmlohuLvmQ/TdBaw2wXjr+xNh4rHXBTPGQCA=";
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
      # cmake hook leaves cwd in the build dir, where the plugin is linked.
      install -Dm755 structor.so $out/plugins/structor.so
      runHook postInstall
    '';

    meta = with lib; {
      description = "Structor - Hex-Rays plugin that synthesizes C structures from raw pointer arithmetic";
      homepage = "https://github.com/19h/ida-structor";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
