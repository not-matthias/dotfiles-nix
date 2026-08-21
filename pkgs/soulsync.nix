{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  python3,
  ffmpeg,
  chromaprint,
}: let
  pname = "soulsync";
  version = "3.2.2";

  pythonEnv = python3.withPackages (ps:
    with ps; [
      flask
      flask-limiter
      spotipy
      plexapi
      requests
      aiohttp
      python-dotenv
      cryptography
      mutagen
      pillow
      unidecode
      beautifulsoup4
      psutil
      yt-dlp
      lrclibapi
      pyacoustid
      websocket-client
      tidalapi
      flask-socketio
    ]);
in
  stdenv.mkDerivation {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "Nezreka";
      repo = "SoulSync";
      rev = version;
      hash = "sha256-ffJ54zRch4gBrf8+en4Lw4T6Wx9/EFFLnByZiE3lhzw=";
    };

    nativeBuildInputs = [makeWrapper];
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/soulsync $out/bin
      cp -r . $out/share/soulsync

      makeWrapper ${pythonEnv}/bin/python $out/bin/soulsync \
        --set PYTHONPATH "$out/share/soulsync" \
        --prefix PATH : "${lib.makeBinPath [pythonEnv ffmpeg chromaprint]}" \
        --add-flags "$out/share/soulsync/web_server.py"

      runHook postInstall
    '';

    meta = {
      description = "Automated music discovery and collection manager";
      homepage = "https://github.com/Nezreka/SoulSync";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "soulsync";
    };
  }
