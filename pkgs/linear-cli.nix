{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "linear-cli";
  version = "2.0.0";

  src = fetchurl {
    url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-x86_64-unknown-linux-gnu.tar.xz";
    hash = "sha256-r/tZRnLC8iDO9o+nz+uBOUXEAQeJpLjMLA5GRo/reHA=";
  };

  sourceRoot = ".";

  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    install -Dm755 linear-x86_64-unknown-linux-gnu/linear $out/bin/linear
  '';

  meta = with lib; {
    description = "CLI for Linear issue tracking";
    homepage = "https://github.com/schpet/linear-cli";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "linear";
  };
}
