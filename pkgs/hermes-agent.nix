{
  lib,
  python312,
  fetchFromGitHub,
  fetchPypi,
  fetchNpmDeps,
  makeWrapper,
  nodejs_22,
  ripgrep,
  ffmpeg,
  git,
}:
# Forked from https://github.com/0xrsydn/nix-hermes-agent/blob/main/package.nix
# Fix: upstream doesn't copy scripts/whatsapp-bridge into the Python package,
# causing `hermes setup whatsapp` to fail with "Bridge script not found".
let
  # Override python package set to fix broken upstream tests
  python = python312.override {
    packageOverrides = _final: prev: {
      sanic = prev.sanic.overridePythonAttrs (_old: {
        # sanic 25.12.0 has a flaky test_keep_alive_client_timeout in nixpkgs sandbox
        doCheck = false;
      });
    };
  };
  pythonPackages = python.pkgs;

  # --- Missing PyPI packages ---

  fal-client = pythonPackages.buildPythonPackage rec {
    pname = "fal-client";
    version = "0.13.1";
    pyproject = true;
    src = fetchPypi {
      pname = "fal_client";
      inherit version;
      hash = "sha256-nhwH0KYbRSqP+0jBmd5fJUPXVG8SMPYxI3BEMSfF6Tc=";
    };
    build-system = with pythonPackages; [
      setuptools
      setuptools-scm
    ];
    dependencies = with pythonPackages; [
      httpx
      httpx-sse
      msgpack
      websockets
    ];
    doCheck = false;
    pythonImportsCheck = ["fal_client"];
  };

  honcho-ai = pythonPackages.buildPythonPackage rec {
    pname = "honcho-ai";
    version = "2.0.1";
    pyproject = true;
    src = fetchPypi {
      pname = "honcho_ai";
      inherit version;
      hash = "sha256-b97r+UVOYrxSPVeIjlA1nme6r9sh9oYh+cFOCNwAYjo=";
    };
    build-system = with pythonPackages; [
      setuptools
      wheel
    ];
    dependencies = with pythonPackages; [
      httpx
      pydantic
      typing-extensions
    ];
    doCheck = false;
    pythonImportsCheck = ["honcho"];
  };

  # nixpkgs 25.05 ships firecrawl-py 1.15.0 which exports FirecrawlApp;
  # hermes needs v2+ which exports Firecrawl
  firecrawl-py = pythonPackages.buildPythonPackage rec {
    pname = "firecrawl-py";
    version = "4.19.0";
    pyproject = true;
    src = fetchPypi {
      pname = "firecrawl_py";
      inherit version;
      hash = "sha256-nKwq5s02c+UARuU5OANagm5R0Zdwq/jcwhuj+zsjXRw=";
    };
    build-system = [pythonPackages.setuptools];
    dependencies = with pythonPackages; [
      requests
      httpx
      python-dotenv
      websockets
      nest-asyncio
      pydantic
      aiohttp
    ];
    doCheck = false;
    pythonImportsCheck = ["firecrawl"];
  };

  agent-client-protocol = pythonPackages.buildPythonPackage rec {
    pname = "agent-client-protocol";
    version = "0.8.1";
    pyproject = true;
    src = fetchPypi {
      pname = "agent_client_protocol";
      inherit version;
      hash = "sha256-G78VZjv1H2SUJZf2OOMqYoTF2pGAVdlnLTUQ6WUUPb0=";
    };
    build-system = [pythonPackages.pdm-backend];
    dependencies = with pythonPackages; [
      pydantic
    ];
    doCheck = false;
    pythonImportsCheck = ["acp"];
  };

  version = "0.3.0";
  rev = "6ebb816e5611aaf1f3f7187ba8b10e985e899c75";

  src = fetchFromGitHub {
    owner = "NousResearch";
    repo = "hermes-agent";
    inherit rev;
    hash = "sha256-JGjusff/jGjvCCdUtl9IErBTGmpIq6BVA5Gj8mwqVYg=";
    fetchSubmodules = true;
  };

  # Pre-fetched npm deps for scripts/whatsapp-bridge
  bridgeNpmDeps = fetchNpmDeps {
    src = "${src}/scripts/whatsapp-bridge";
    hash = "sha256-4WOmAgCNDX1/Mz2XTF34yBAr8T+PeEBJKdkD1fN+1uY=";
  };
in
  pythonPackages.buildPythonApplication {
    pname = "hermes-agent";
    inherit version src;
    pyproject = true;

    build-system = [pythonPackages.setuptools];

    dependencies = with pythonPackages;
      [
        # Core
        openai
        anthropic
        python-dotenv
        fire
        httpx
        rich
        tenacity
        pyyaml
        requests
        jinja2
        pydantic
        prompt-toolkit
        # TTS
        edge-tts
        faster-whisper
        # mini-swe-agent deps
        litellm
        typer
        platformdirs
        # Skills Hub
        pyjwt
        # Messaging
        python-telegram-bot
        discordpy
        aiohttp
        slack-bolt
        slack-sdk
        # Cron
        croniter
        # CLI
        simple-term-menu
        # TTS premium
        elevenlabs
        # Voice
        sounddevice
        numpy
        # PTY
        ptyprocess
        # MCP
        mcp
        # Custom-built packages (not in nixpkgs or too old)
      ]
      ++ [
        firecrawl-py
        fal-client
        honcho-ai
        agent-client-protocol
      ];

    nativeBuildInputs = [makeWrapper nodejs_22];

    # Don't run tests during build
    doCheck = false;

    # Upstream pyproject.toml is missing minisweagent_path from py-modules.
    # Also ensure mini-swe-agent/src is importable.
    postPatch = ''
      # Fix: add minisweagent_path.py to py-modules if missing from pyproject.toml
      if [ -f minisweagent_path.py ] && ! grep -q minisweagent_path pyproject.toml; then
        sed -i 's/py-modules = \[/py-modules = ["minisweagent_path", /' pyproject.toml
      fi

      # Make mini-swe-agent importable by copying src into the package
      if [ -d mini-swe-agent/src/minisweagent ]; then
        cp -r mini-swe-agent/src/minisweagent .
      fi
    '';

    # Copy scripts/ into site-packages and pre-install WhatsApp bridge npm deps
    # (the nix store is read-only, so hermes can't npm install at runtime)
    postInstall = ''
      local siteDir="$out/lib/${python.libPrefix}/site-packages"
      cp -r "$src/scripts" "$siteDir/scripts"
      chmod -R u+w "$siteDir/scripts"

      local tmpCache=$(mktemp -d)
      cp -r ${bridgeNpmDeps}/* "$tmpCache/" 2>/dev/null || true
      chmod -R u+w "$tmpCache"

      cd "$siteDir/scripts/whatsapp-bridge"
      HOME="$TMPDIR" npm ci --cache "$tmpCache" --ignore-scripts
      cd -

      rm -rf "$tmpCache"
    '';

    postFixup = ''
      # Wrap binaries with runtime deps on PATH
      for bin in $out/bin/hermes $out/bin/hermes-agent $out/bin/hermes-acp; do
        if [ -f "$bin" ]; then
          wrapProgram "$bin" \
            --prefix PATH : ${
        lib.makeBinPath [
          nodejs_22
          ripgrep
          ffmpeg
          git
        ]
      }
        fi
      done
    '';

    passthru = {
      upstreamSrc = src;
    };

    meta = with lib; {
      description = "The self-improving AI agent by Nous Research";
      homepage = "https://github.com/NousResearch/hermes-agent";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "hermes";
      platforms = platforms.linux ++ platforms.darwin;
    };
  }
