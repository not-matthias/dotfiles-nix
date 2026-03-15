{
  lib,
  buildNpmPackage,
  nodejs_22,
  pnpmConfigHook,
  fetchPnpmDeps,
  src,
  npmDepsHash ? null,
  pnpmDepsHash ? null,
}: let
  hasNpmDeps = npmDepsHash != null;
  hasPnpmDeps = pnpmDepsHash != null;
in
  if (hasNpmDeps && hasPnpmDeps) || (!hasNpmDeps && !hasPnpmDeps)
  then throw "with-runtime-deps.nix requires exactly one of npmDepsHash or pnpmDepsHash"
  else
    buildNpmPackage (
      {
        pname = "pi-extension-runtime";
        version = "1.0.0";

        inherit src;
        nodejs = nodejs_22;

        dontNpmBuild = true;
        npmInstallFlags = [
          "--omit=dev"
          "--ignore-scripts"
        ];

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -R . $out/
          runHook postInstall
        '';
      }
      // lib.optionalAttrs hasNpmDeps {
        inherit npmDepsHash;
      }
      // lib.optionalAttrs hasPnpmDeps {
        inherit pnpmConfigHook;
        npmDeps = null;
        pnpmDeps = fetchPnpmDeps {
          inherit src;
          pname = "pi-extension-runtime";
          version = "1.0.0";
          fetcherVersion = 2;
          hash = pnpmDepsHash;
        };
      }
    )
