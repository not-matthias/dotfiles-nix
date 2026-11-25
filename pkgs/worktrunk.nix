{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "0.83.0";
  assets = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-4N1eXrNliQ3ceyVRg8In5EH7t9oEyrW3LlT6gP0hgYs=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-ksaIJ6GLA3xgi3covPfOHVlHcayBS+x0EqNRKfJ21K4=";
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
      install -Dm644 LICENSE-MIT "$out/share/licenses/worktrunk/LICENSE-MIT"
      install -Dm644 LICENSE-APACHE "$out/share/licenses/worktrunk/LICENSE-APACHE"
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
