{
  stdenvNoCC,
  buildNpmPackage,
  nodejs_22,
  pnpm_9,
  src,
  npmDepsHash ? null,
  pnpmDepsHash ? null,
}: let
  hasNpmDeps = npmDepsHash != null;
  hasPnpmDeps = pnpmDepsHash != null;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';

  npmBuild = buildNpmPackage {
    pname = "pi-extension-runtime";
    version = "1.0.0";

    inherit src npmDepsHash;
    nodejs = nodejs_22;

    dontNpmBuild = true;
    npmInstallFlags = [
      "--omit=dev"
      "--omit=peer"
      "--ignore-scripts"
    ];

    inherit installPhase;
  };

  pnpmBuild = stdenvNoCC.mkDerivation {
    pname = "pi-extension-runtime";
    version = "1.0.0";

    inherit src;

    nativeBuildInputs = [
      nodejs_22
      pnpm_9.configHook
    ];

    pnpmDeps = pnpm_9.fetchDeps {
      pname = "pi-extension-runtime";
      version = "1.0.0";
      inherit src;
      hash = pnpmDepsHash;
      fetcherVersion = 2;
    };

    dontBuild = true;

    inherit installPhase;
  };
in
  if (hasNpmDeps && hasPnpmDeps) || (!hasNpmDeps && !hasPnpmDeps)
  then throw "with-runtime-deps.nix requires exactly one of npmDepsHash or pnpmDepsHash"
  else if hasNpmDeps
  then npmBuild
  else pnpmBuild
