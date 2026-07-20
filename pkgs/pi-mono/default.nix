{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "pi-coding-agent";
  version = "0.80.10";

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-x64.tar.gz";
    hash = "sha256-q2YE9sPz0FB4Pnq7vdH3m3dbIPOWmDPOlyF0BoXQHhM=";
  };

  sourceRoot = "pi";

  dontStrip = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi $out/bin
    cp -r . $out/lib/pi
    chmod +x $out/lib/pi/pi
    makeWrapper $out/lib/pi/pi $out/bin/pi \
      --set PI_SKIP_VERSION_CHECK 1 \
      --run 'export NPM_CONFIG_PREFIX="''${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"' \
      --run 'export PATH="''${NPM_CONFIG_PREFIX:-$HOME/.npm-global}/bin:$PATH"'

    runHook postInstall
  '';

  meta = {
    description = "Minimal terminal coding harness - extensible with TypeScript extensions, skills, and prompt templates";
    homepage = "https://github.com/earendil-works/pi";
    downloadPage = "https://github.com/earendil-works/pi/releases";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "pi";
  };
}
