{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-autoresearch";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "davebcn87";
    repo = "pi-autoresearch";
    rev = "dab7046feedfcc47b406eef36e59a3f4a0d9e508";
    hash = "sha256-UZi/lQyFsjYEj94vA13HlCP+PDYscEXu50a6Uu9vYmE=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';

  meta = {
    description = "Autonomous experiment loop for pi — run, measure, keep or discard";
    homepage = "https://github.com/davebcn87/pi-autoresearch";
    license = lib.licenses.mit;
  };
}
