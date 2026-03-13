{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  fetchPypi,
  makeWrapper,
  python312,
  ffmpeg,
}: let
  pname = "audiomuse-ai";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "NeptuneHub";
    repo = "AudioMuse-AI";
    rev = "7facd2628b2dfb9f1b06b798ba92aae1d4dbf1d2";
    hash = "sha256-rx8dW+7QqBD163Ls1GHmkEvfaTqfm0YF24TAar9nUSY=";
  };

  voyager = python312.pkgs.buildPythonPackage rec {
    pname = "voyager";
    version = "2.1.0";
    format = "wheel";

    src = fetchPypi {
      inherit pname version format;
      dist = "cp312";
      python = "cp312";
      abi = "cp312";
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-lBW5ySO6xJPVxo1VrlXEKJFTwj+fR4Qik03mGsuvTAE=";
    };

    pythonImportsCheck = [];
  };

  mistralai = python312.pkgs.buildPythonPackage rec {
    pname = "mistralai";
    version = "1.11.1";
    format = "wheel";

    src = fetchPypi {
      inherit pname version format;
      dist = "py3";
      python = "py3";
      abi = "none";
      platform = "any";
      hash = "sha256-w2LM2IQESL89unyI69loPQdvAogpjdh6UeTL3ubq+sE=";
    };

    propagatedBuildInputs = with python312.pkgs; [
      eval-type-backport
      httpx
      invoke
      opentelemetry-api
      pydantic
      python-dateutil
      typing-extensions
    ];

    pythonImportsCheck = [];
    doCheck = false;
  };

  pythonEnv = python312.withPackages (
    ps:
      with ps; [
        flask
        flask-cors
        flasgger
        redis
        rq
        psycopg2
        librosa
        soundfile
        resampy
        pydub
        mutagen
        numpy
        scipy
        numba
        scikit-learn
        umap-learn
        transformers
        sentencepiece
        onnx
        onnxruntime
        pyyaml
        requests
        rapidfuzz
        ftfy
        packaging
        protobuf
        httpx
        google-genai
        mcp
        pyjwt
        sqlglot
        gunicorn
        zstandard
        psutil
        mpd2
        voyager
        mistralai
      ]
  );
in
  stdenvNoCC.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [makeWrapper];

    postPatch = ''
      substituteInPlace config.py \
        --replace-fail 'TEMP_DIR = "/app/temp_audio"' 'TEMP_DIR = os.environ.get("TEMP_DIR", "/tmp/audiomuse-temp")'
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/audiomuse-ai
      cp -r . $out/lib/audiomuse-ai/

      mkdir -p $out/bin

      makeWrapper ${pythonEnv}/bin/python $out/bin/audiomuse-ai \
        --add-flags "$out/lib/audiomuse-ai/app.py" \
        --prefix PATH : ${lib.makeBinPath [ffmpeg]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [stdenv.cc.cc.lib]} \
        --set PYTHONPATH "$out/lib/audiomuse-ai" \
        --set-default TEMP_DIR "/tmp/audiomuse-temp"

      makeWrapper ${pythonEnv}/bin/python $out/bin/audiomuse-ai-worker \
        --add-flags "$out/lib/audiomuse-ai/rq_worker.py" \
        --prefix PATH : ${lib.makeBinPath [ffmpeg]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [stdenv.cc.cc.lib]} \
        --set PYTHONPATH "$out/lib/audiomuse-ai" \
        --set-default TEMP_DIR "/tmp/audiomuse-temp"

      makeWrapper ${pythonEnv}/bin/python $out/bin/audiomuse-ai-worker-high \
        --add-flags "$out/lib/audiomuse-ai/rq_worker_high_priority.py" \
        --prefix PATH : ${lib.makeBinPath [ffmpeg]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [stdenv.cc.cc.lib]} \
        --set PYTHONPATH "$out/lib/audiomuse-ai" \
        --set-default TEMP_DIR "/tmp/audiomuse-temp"

      runHook postInstall
    '';

    meta = {
      description = "AI-powered music analysis and playlist generation";
      homepage = "https://github.com/NeptuneHub/AudioMuse-AI";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "audiomuse-ai";
    };
  }
