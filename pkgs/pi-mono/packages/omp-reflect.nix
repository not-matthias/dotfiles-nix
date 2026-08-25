{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  nodejs_22,
  runCommand,
}: let
  pname = "omp-reflect";
  version = "0.1.0";

  rawSrc = fetchFromGitHub {
    owner = "praneybehl";
    repo = "omp-reflect";
    rev = "6097b386bdc04fe91f9c334be159dbda730f6504";
    hash = "sha256-M2A1K6+XXTBC6WJejshvuL1Or81d8dzMynth4fjM6KY=";
  };

  src = runCommand "${pname}-src" {} ''
    cp -r ${rawSrc} $out
    chmod -R +w $out
    cp ${./omp-reflect-package-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    inherit pname version src;

    nodejs = nodejs_22;
    npm_config_ignore_scripts = "true";
    npmDeps = fetchNpmDeps {
      name = "${pname}-${version}-npm-deps";
      inherit src;
      hash = "sha256-TH7EA5a/Ut3qhW7RIs0AKBLG493QxtndlJVLOjNkF5Q=";
    };

    dontNpmBuild = true;
    npmInstallFlags = ["--omit=dev" "--omit=peer" "--ignore-scripts"];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R . $out/
      runHook postInstall
    '';
  }
