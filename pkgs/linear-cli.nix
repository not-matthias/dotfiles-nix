{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation rec {
  pname = "linear-cli";
  version = "3.1.0";

  src = fetchurl {
    url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-x86_64-unknown-linux-gnu.tar.xz";
    hash = "sha256-v3cSCXzmoB6KN53oNX7KZtV0gFAgHTNrp4e2rTaH8+c=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib];
  dontStrip = true;

  installPhase = ''
    install -Dm755 linear-x86_64-unknown-linux-gnu/linear $out/bin/linear
    install -Dm444 linear-x86_64-unknown-linux-gnu/LICENSE $out/share/doc/linear/LICENSE
    install -Dm444 linear-x86_64-unknown-linux-gnu/THIRD_PARTY_LICENSES.md $out/share/doc/linear/THIRD_PARTY_LICENSES.md
  '';

  meta = with lib; {
    description = "CLI for Linear issue tracking";
    homepage = "https://github.com/schpet/linear-cli";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "linear";
  };
}
