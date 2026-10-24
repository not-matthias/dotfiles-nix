{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "0.81.0";
  assets = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-DCU/IWmFzpzXsgKhFga1zmqpNLEBn9H7ubfOK0exx0o=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-ejNNLmTFd6/QJH4kEe/2czYKsfGIl1ZPLS5dU3T710s=";
    };
  };
  asset = assets.${stdenvNoCC.hostPlatform.system}
    or (throw "worktrunk ${version} is not available for ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "worktrunk";
    inherit version;

    # Release binaries are static-pie musl builds, so no ELF patching is needed.
    src = fetchurl {
      url = "https://github.com/max-sixty/worktrunk/releases/download/v${version}/worktrunk-${asset.target}.tar.xz";
      inherit (asset) hash;
    };

    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 wt "$out/bin/wt"
      install -Dm644 LICENSE "$out/share/licenses/worktrunk/LICENSE"
      runHook postInstall
    '';

    meta = {
      description = "CLI for Git worktree management, designed for parallel AI agent workflows";
      homepage = "https://worktrunk.dev";
      downloadPage = "https://github.com/max-sixty/worktrunk/releases";
      license = with lib.licenses; [mit asl20];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames assets;
      mainProgram = "wt";
    };
  }
