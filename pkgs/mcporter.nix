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
  version = "0.13.6";
  pnpm = pnpm_10;
  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "mcporter";
    rev = "e53ef107e4c937478b89ff17411526520e448a51";
    hash = "sha256-HjxGKxthGRG8Ta56wjlFTApKAzpH7wc4HB9lgvVAg7U=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src pnpm;
      fetcherVersion = 3;
      hash = "sha256-uzn6SM04FmeunRo4HoSdh1yzVLXrq0FoQtEdbCu5+Hw=";
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
