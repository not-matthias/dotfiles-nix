{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  patchelf,
  makeWrapper,
  xclip,
  procps,
}: let
  version = "0.17.0";
  platforms = {
    x86_64-linux = {
      asset = "slackcli-linux";
      hash = "sha256-WybTHMnOpbVcN30PnDIDmQTuS8gIPozGcMGwcBF4RgA=";
    };
    aarch64-linux = {
      asset = "slackcli-linux-arm64";
      hash = "sha256-F6SIAc1NKtZn3JYkK78Try2PXGdmhBoZuQXONUeVfrg=";
    };
  };
  platform =
    platforms.${stdenvNoCC.hostPlatform.system}
    or (throw "slackcli: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "slackcli";
    inherit version;

    src = fetchurl {
      url = "https://github.com/shaharia-lab/slackcli/releases/download/v${version}/${platform.asset}";
      inherit (platform) hash;
    };

    dontUnpack = true;
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = [patchelf makeWrapper];

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/libexec/slackcli"
      patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
        "$out/libexec/slackcli"
      makeWrapper "$out/libexec/slackcli" "$out/bin/slackcli" \
        --prefix PATH : ${lib.makeBinPath [xclip procps]} \
        --set-default SLACKCLI_NO_UPDATE_NOTIFIER 1
      runHook postInstall
    '';

    meta = with lib; {
      description = "Slack CLI for humans and AI agents";
      homepage = "https://slackcli.dev/";
      downloadPage = "https://github.com/shaharia-lab/slackcli/releases";
      changelog = "https://github.com/shaharia-lab/slackcli/releases/tag/v${version}";
      license = licenses.mit;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      platforms = builtins.attrNames platforms;
      mainProgram = "slackcli";
    };
  }
