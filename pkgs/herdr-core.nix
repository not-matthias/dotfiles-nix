{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "0.1.13";
  assets = {
    x86_64-linux = {
      target = "linux-x86_64";
      hash = "sha256-0Nv91uBggyximmrtA2hxZUebrOq1pVRaEDSQ0OStq4w=";
    };
    aarch64-linux = {
      target = "linux-aarch64";
      hash = "sha256-gqvDDer259rso8YO78EnCPAhD5RcKAYmdL5x/P3he9U=";
    };
  };
  asset = assets.${stdenvNoCC.hostPlatform.system}
    or (throw "Herdr core ${version} is not available for ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "herdr-core";
    inherit version;
    src = fetchurl {
      url = "https://releases.herdr.dev/core/${version}/herdr-core-${asset.target}.tar.gz";
      inherit (asset) hash;
    };

    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      tar xzf "$src"
      install -Dm755 herdr-core "$out/bin/herdr-core"
      ln -s herdr-core "$out/bin/hc"
      runHook postInstall
    '';

    meta = {
      description = "Persistent terminals for coding agents";
      homepage = "https://github.com/herdrdev/herdr-core";
      license = lib.licenses.asl20;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames assets;
      mainProgram = "herdr-core";
    };
  }
