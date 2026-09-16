{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_10,
  npmHooks,
  versionCheckHook,
  nix-update-script,
}: let
  pname = "mcporter";
  version = "0.13.13";
  pnpm = pnpm_10;
  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "mcporter";
    rev = "e4cb002200e44460279d414b0d1dec597b978f06";
    hash = "sha256-0RvHJlAqdH+mPM2O/0kAPDWSrW/tbekGdG6pv1lms/Q=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src pnpm;
      fetcherVersion = 3;
      hash = "sha256-96qhsVIc5aIyow6VcZ670Us8tSLqPlocT1h7x8SbPBI=";
    };

    nativeBuildInputs = [
      nodejs
      pnpmConfigHook
      pnpm
      npmHooks.npmInstallHook
    ];

    buildPhase = ''
      runHook preBuild

      pnpm run build

      runHook postBuild
    '';

    dontNpmPrune = true;

    nativeInstallCheckInputs = [
      versionCheckHook
    ];

    doInstallCheck = true;

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "TypeScript runtime and CLI for connecting to configured Model Context Protocol servers";
      homepage = "https://github.com/openclaw/mcporter";
      changelog = "https://github.com/openclaw/mcporter/releases/tag/v${version}";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [mkg20001];
      mainProgram = "mcporter";
    };
  }
