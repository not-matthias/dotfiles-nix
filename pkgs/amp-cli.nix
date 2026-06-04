{
  stdenvNoCC,
  lib,
  fetchurl,
  autoPatchelfHook,
  gzip,
  makeWrapper,
  ripgrep,
}: let
  platforms = {
    x86_64-linux = "linux-x64-baseline";
    aarch64-linux = "linux-arm64";
  };
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "amp-cli";
    version = "0.0.1780421295-g521930";

    src = finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system};

    nativeBuildInputs = [
      gzip
      makeWrapper
      autoPatchelfHook
    ];
    strictDeps = true;

    dontUnpack = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/libexec/amp-cli
      gunzip -c $src > $out/libexec/amp-cli/amp
      chmod +x $out/libexec/amp-cli/amp

      makeWrapper $out/libexec/amp-cli/amp $out/bin/amp \
        --set AMP_SKIP_UPDATE_CHECK 1 \
        --prefix PATH : ${lib.makeBinPath [ripgrep]}

      runHook postInstall
    '';

    passthru.sources =
      lib.mapAttrs (
        system': platform:
          fetchurl {
            url = "https://static.ampcode.com/cli/${finalAttrs.version}/amp-${platform}.gz";
            hash =
              {
                x86_64-linux = "sha256-EjNQKsgugwvybKw9SyFo7Zezg3O7xUI1NeMYsfRKRXM=";
                aarch64-linux = "sha256-cADeoFQUGqVTGVDRQON4lZd4blFgeCLJorIGA15sUTw=";
              }
            .${
                system'
              };
          }
      )
      platforms;

    meta = {
      description = "CLI for Amp, an agentic coding agent from Sourcegraph";
      homepage = "https://ampcode.com/";
      license = lib.licenses.unfree;
      mainProgram = "amp";
      platforms = builtins.attrNames platforms;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  })
