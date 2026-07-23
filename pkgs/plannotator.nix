{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  patchelf,
  makeWrapper,
  git,
}: let
  version = "0.24.2";

  platforms = {
    x86_64-linux = {
      path = "linux-x64";
      hash = "sha256-6cyScQhh/1hD8XQmst/I4NKWEwxmciRBAejBUy8f2A0=";
    };
    aarch64-linux = {
      path = "linux-arm64";
      hash = "sha256-jJkVjFxWj6lqBojruLBiRpBfvZNnaJ/LZmpqRx+u1KU=";
    };
  };

  platform =
    platforms.${stdenvNoCC.hostPlatform.system}
    or (throw "plannotator: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "plannotator";
    inherit version;

    src = fetchurl {
      url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-${platform.path}";
      inherit (platform) hash;
    };

    dontUnpack = true;
    dontStrip = true;
    # Bun standalone binaries have JS resources appended after the ELF structure.
    # --set-rpath corrupts this appended data; only --set-interpreter is safe.
    dontPatchELF = true;

    nativeBuildInputs = [patchelf makeWrapper];

    installPhase = ''
      runHook preInstall

      install -Dm755 "$src" "$out/libexec/plannotator"

      patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
        "$out/libexec/plannotator"

      makeWrapper "$out/libexec/plannotator" "$out/bin/plannotator" \
        --prefix PATH : ${lib.makeBinPath [git]}

      runHook postInstall
    '';

    meta = with lib; {
      description = "Annotate and review coding agent plans and code diffs visually";
      homepage = "https://plannotator.ai";
      downloadPage = "https://github.com/backnotprop/plannotator/releases";
      license = licenses.asl20;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "plannotator";
      platforms = builtins.attrNames platforms;
    };
  }
