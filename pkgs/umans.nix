{
  lib,
  stdenvNoCC,
  fetchurl,
  python3,
}:

stdenvNoCC.mkDerivation rec {
  pname = "umans";
  version = "0.1.43";

  src = fetchurl {
    url = "https://api.code.umans.ai/cli/umans";
    hash = "sha256-bsHmx+E88mKZnQ4Ff89doiwtO88q0gcTQJy9X3ricUQ=";
  };

  dontUnpack = true;

  nativeBuildInputs = [python3];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/umans
    patchShebangs $out/bin/umans

    runHook postInstall
  '';

  meta = {
    description = "CLI for using coding agents with the Umans backend";
    homepage = "https://code.umans.ai";
    license = lib.licenses.unfree;
    mainProgram = "umans";
    platforms = lib.platforms.unix;
  };
}
