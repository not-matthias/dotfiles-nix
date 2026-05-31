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
    version = "0.0.1779920297-gb3c071";

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
                x86_64-linux = "sha256-BAU9qmbrJc+iwjmGNR1ScxLSVHI0GDt0mWaHNm5p0dE=";
                aarch64-linux = "sha256-fh/g6i01oNg1MZPN4WnVK/lo4PgUDp5ETysUhWhvuXQ=";
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
