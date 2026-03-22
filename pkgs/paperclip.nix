# Paperclip — open-source AI agent orchestration platform
# https://github.com/paperclipai/paperclip
#
# This packages the paperclipai CLI which bundles the server + embedded postgres.
# Run with: paperclipai start
{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  pnpm_9,
  python3,
  postgresql_16,
  makeWrapper,
  autoPatchelfHook,
  glibc,
}: let
  pname = "paperclip";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "paperclipai";
    repo = "paperclip";
    tag = "v${version}";
    hash = "sha256-t0tvIoKx6L0QzRmU0L80mz87VECskpzuHR0eCUOj9XI=";
  };

  pnpm = pnpm_9;
in
  buildNpmPackage {
    inherit pname version src;

    npmConfigHook = pnpm.configHook;

    npmDeps = null;
    pnpmDeps = pnpm.fetchDeps {
      inherit pname version src;
      fetcherVersion = 2;
      hash = "sha256-O7znHAOnEy+h6OFnqQC+d22XFMheCeUbwHeoscmkLm4=";
    };

    nativeBuildInputs = [
      nodejs_22
      makeWrapper
      python3 # needed for node-gyp native addons
      autoPatchelfHook
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      glibc
    ];

    # embedded-postgres ships platform-specific binaries that need patching
    autoPatchelfIgnoreMissingDeps = true;

    env = {
      ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    };

    buildPhase = ''
      runHook preBuild

      # pnpm strict mode doesn't hoist transitive deps (e.g. zod) to
      # workspace packages that import them. Hoist everything so the
      # CLI can resolve all deps at runtime.
      echo "shamefully-hoist=true" >> .npmrc
      pnpm install --frozen-lockfile

      # Build all workspace packages
      pnpm --filter @paperclipai/shared build
      pnpm --filter @paperclipai/db build
      pnpm --filter @paperclipai/adapter-utils build
      pnpm --filter @paperclipai/adapter-claude-local build
      pnpm --filter @paperclipai/adapter-codex-local build
      pnpm --filter @paperclipai/adapter-cursor-local build
      pnpm --filter @paperclipai/adapter-gemini-local build
      pnpm --filter @paperclipai/adapter-opencode-local build
      pnpm --filter @paperclipai/adapter-openclaw-gateway build
      pnpm --filter @paperclipai/ui build
      pnpm --filter @paperclipai/server build
      pnpm --filter paperclipai build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/paperclip
      cp -r . $out/lib/paperclip/

      mkdir -p $out/bin
      makeWrapper ${nodejs_22}/bin/node $out/bin/paperclipai \
        --add-flags "$out/lib/paperclip/cli/dist/index.js" \
        --prefix PATH : ${lib.makeBinPath [postgresql_16]} \
        --set NODE_PATH "$out/lib/paperclip/node_modules"

      runHook postInstall
    '';

    meta = {
      description = "Open-source orchestration for AI agent teams";
      homepage = "https://github.com/paperclipai/paperclip";
      license = lib.licenses.mit;
      mainProgram = "paperclipai";
      platforms = lib.platforms.linux;
    };
  }
