{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}: let
  version = "0.1.10";
  assets = {
    x86_64-linux = {
      name = "herdr-mirror-linux-x86_64";
      hash = "sha256-dNJVf9A9h4b8UkKh/TQ3Xac1WMlGdAvo+8/cV5Mj9s4=";
    };
    aarch64-linux = {
      name = "herdr-mirror-linux-aarch64";
      hash = "sha256-NMtOaoxk3AfGaOTbkSySf1Q5G2AWJcSBRtQ6JfttEPc=";
    };
  };
  asset =
    assets.${stdenvNoCC.hostPlatform.system}
    or (throw "herdr-mirror ${version} is not available for ${stdenvNoCC.hostPlatform.system}");
  binary = fetchurl {
    url = "https://github.com/nikok6/herdr-mirror/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };
in
  stdenvNoCC.mkDerivation {
    pname = "herdr-mirror-plugin";
    inherit version;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/target/release
      install -Dm644 ${./mirror/herdr-plugin.toml} $out/herdr-plugin.toml
      install -m755 ${binary} $out/target/release/herdr-mirror
      runHook postInstall
    '';

    meta = {
      description = "Herdr plugin that mirrors remote herdr servers into the local sidebar";
      homepage = "https://github.com/nikok6/herdr-mirror";
      license = lib.licenses.mit;
      platforms = lib.attrNames assets;
    };
  }
