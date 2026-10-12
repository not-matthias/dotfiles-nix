{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "paper-mono";
  version = "1.000";

  src = fetchurl {
    url = "https://github.com/paper-design/paper-mono/releases/download/v${version}/paper-mono-v${version}.zip";
    hash = "sha256-hkJlKYXch79M/QfImUKJnmEcPHdPwlKEwN1P6GqZOhM=";
  };

  nativeBuildInputs = [unzip];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 fonts/ttf/*.ttf -t "$out/share/fonts/truetype"
    install -Dm644 OFL.txt "$out/share/licenses/paper-mono/OFL.txt"
    runHook postInstall
  '';

  meta = {
    description = "Monospace font family for design and code";
    homepage = "https://paper.design/mono";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
