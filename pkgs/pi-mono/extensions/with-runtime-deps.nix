{
  stdenvNoCC,
  buildNpmPackage,
  fetchNpmDeps,
  nodejs_22,
  pnpm_9,
  src,
  npmDepsHash ? null,
  pnpmDepsHash ? null,
  doBuild ? false,
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

    inherit src;
    nodejs = nodejs_22;

    dontNpmBuild = !doBuild;
    npmInstallFlags = (
      if doBuild
      then []
      else [
        "--omit=dev"
        "--omit=peer"
        "--ignore-scripts"
      ]
    );

    # Custom npmDeps with retry logic for transient HTTP/2 stream errors
    npmDeps = fetchNpmDeps {
      name = "pi-extension-runtime-1.0.0-npm-deps";
      inherit src;
      hash = npmDepsHash;
      buildPhase = ''
        runHook preBuild

        if [[ -f npm-shrinkwrap.json ]]; then
          local -r srcLockfile="npm-shrinkwrap.json"
        elif [[ -f package-lock.json ]]; then
          local -r srcLockfile="package-lock.json"
        else
          echo "ERROR: No lock file found"
          exit 1
        fi

        local attempt=0
        local max_attempts=3
        while (( attempt < max_attempts )); do
          attempt=$((attempt + 1))
          echo "prefetch-npm-deps attempt $attempt/$max_attempts"
          if prefetch-npm-deps "$srcLockfile" "$out"; then
            break
          fi
          if (( attempt < max_attempts )); then
            echo "Retrying in 5 seconds..."
            sleep 5
          else
            echo "All $max_attempts attempts failed"
            exit 1
          fi
        done

        runHook postBuild
      '';
    };

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
