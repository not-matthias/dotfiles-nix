{
  pkgs,
  lib,
  fetchFromGitHub,
  ...
}:
pkgs.stdenv.mkDerivation {
  pname = "ida-bitopt";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "teflate";
    repo = "bitopt";
    rev = "b25b2adc36d9bf7449a3c64b3ab6661c558547d6";
    hash = "sha256-YKn/8w/EGYoMBy2Ogd1gMuC8xCUiV5yi3ENH+YswYmg=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/plugins
    cp -r plugins/* $out/plugins/
    cp ida-plugin.json $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "IDA Pro optimization passes for ROL, ROR, and byteswap intrinsics";
    homepage = "https://github.com/teflate/bitopt";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
