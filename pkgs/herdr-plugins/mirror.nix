{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}: let
  version = "0.4.3";
  assets = {
    x86_64-linux = {
      name = "herdr-mirror-linux-x86_64";
      hash = "sha256-FbZLS5OljpTnDmm0YhQGma/7soYxc35TnMo0vAnptig=";
    };
    aarch64-linux = {
      name = "herdr-mirror-linux-aarch64";
      hash = "sha256-eYmIMgVn3A3R+uiqczrW+Ffx3Hk8+8+fqBEgr0WniX8=";
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
