{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "audiomuse-ai-nv-plugin";
  version = "6";

  src = fetchurl {
    url = "https://github.com/NeptuneHub/AudioMuse-AI-NV-plugin/releases/download/v${version}/audiomuseai.ndp";
    hash = "sha256-jEA7z1zhcgISYd1jlmyl267jSa15Q+Pi8Jpbw5Xqbvo=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/navidrome-plugins
    install -m444 $src $out/share/navidrome-plugins/audiomuseai.ndp
    runHook postInstall
  '';

  meta = {
    description = "AudioMuse-AI plugin package for Navidrome";
    homepage = "https://github.com/NeptuneHub/AudioMuse-AI-NV-plugin";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
