{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  openssl,
  gcc-unwrapped,
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-session-cli";
  version = "0.4.9";

  src = fetchurl {
    url = "https://github.com/Dwsy/pi-session-manager/releases/download/v${version}/pi-session-cli-linux-x64.tar.gz";
    hash = "sha256-f61NYP98F8tge9OqJFXEtx9fbVh0pllgVV3kXY/HKDc=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [openssl gcc-unwrapped.lib];

  installPhase = ''
    runHook preInstall
    install -Dm755 pi-session-cli-linux-x64 $out/bin/pi-session-cli
    runHook postInstall
  '';

  meta = {
    description = "CLI for browsing, searching, and resuming Pi coding sessions";
    homepage = "https://github.com/Dwsy/pi-session-manager";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "pi-session-cli";
  };
}
