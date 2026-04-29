{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-autoresearch";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "davebcn87";
    repo = "pi-autoresearch";
    rev = "37a611f460f07be353c86dc4596542c03946a2a7";
    hash = "sha256-1KeUUN6odbKv/Z/S6rUQa9k1vcIJYVOeTvRpX8dDAoY=";
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
