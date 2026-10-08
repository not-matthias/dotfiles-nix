{
  lib,
  fetchzip,
  fetchurl,
  runCommand,
  stdenv,
  patchelf,
  alsa-lib,
}: let
  version = "3.0.47";
  src = fetchzip {
    url = "https://registry.npmjs.org/@howaboua/pi-codex-conversion/-/pi-codex-conversion-${version}.tgz";
    hash = "sha256-WnlNOcbR/BhwhjUHu8wulkHUinB88OuAv7n/RPWAbpk=";
  };
  platform =
    {
      x86_64-linux = {
        name = "linux-x64";
        target = "x86_64-unknown-linux-musl";
        hash = "sha256-rCMXeVbDDMH58YDCe9gPW7W3Z4DbVfuU3MImRNSQhS4=";
      };
      aarch64-linux = {
        name = "linux-arm64";
        target = "aarch64-unknown-linux-musl";
        hash = "sha256-IrWGLHIGvJRPWUAturS0Fp44GuimjwFEqbp7Ybzz3Tk=";
      };
    }.${
      stdenv.hostPlatform.system
    };
  # Match the host release pinned by the extension's code-mode/host-assets module.
  host = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v0.145.0/codex-code-mode-host-${platform.target}.tar.gz";
    inherit (platform) hash;
  };
in
  runCommand "pi-codex-conversion-${version}-src" {nativeBuildInputs = [patchelf];} ''
    cp -R ${src} $out
    chmod -R u+w $out
    for binary in \
      $out/src/tools/apply-patch/bin/${platform.name}/apply_patch \
      $out/src/tools/exec/bin/${platform.name}/exec_bridge \
      $out/src/tools/view-image/bin/${platform.name}/view_image \
      $out/src/voice/bin/${platform.name}/pi-codex-voice; do
      patchelf \
        --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
        --set-rpath ${lib.makeLibraryPath [stdenv.cc.cc.lib stdenv.cc.libc alsa-lib]} \
        "$binary"
    done
    hostDir=$out/code-mode/bin/${platform.name}
    mkdir -p "$hostDir"
    tar xzf ${host} -C "$hostDir"
    mv "$hostDir/codex-code-mode-host-${platform.target}" "$hostDir/codex-code-mode-host"
    chmod +x "$hostDir/codex-code-mode-host"
  ''
