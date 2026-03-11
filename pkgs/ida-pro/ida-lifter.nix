{
  pkgs,
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  clang,
  ...
}: let
  inherit (pkgs) stdenv;
  ida-sdk = pkgs.callPackage ./ida-sdk-source.nix {};
in
  stdenv.mkDerivation rec {
    pname = "ida-lifter";
    version = "2.2.0";

    src = fetchFromGitHub {
      owner = "19h";
      repo = "ida-lifter";
      rev = "v${version}";
      hash = "sha256-cyb/vJKwfJR8dHsDO8w41qXbNMgkRGBTjQa3pGtyA7Y=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [
      cmake
      ninja
      clang
    ];

    NIX_CFLAGS_COMPILE = "-Wno-error -Wno-format-security";

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DIDA_SDK_DIR=${ida-sdk}"
      "-DCMAKE_CXX_FLAGS=-Wno-error -Wno-format-security"
    ];

    preConfigure = ''
      export IDASDK=${ida-sdk}
      # ida-cmake tries to write to SDK dir, so we need to copy SDK to a writable location
      export TMP_SDK_DIR=$TMPDIR/ida-sdk-$$
      cp -r ${ida-sdk} $TMP_SDK_DIR
      chmod -R u+w $TMP_SDK_DIR
      export IDASDK=$TMP_SDK_DIR
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/plugins
      cp build/lifter.so $out/plugins/ 2>/dev/null || true

      runHook postInstall
    '';

    meta = with lib; {
      description = "Hex-Rays microcode filter that lifts AVX/AVX2/AVX-512/AVX10 and VMX/VT-x instructions to intrinsics";
      homepage = "https://github.com/19h/ida-lifter";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
