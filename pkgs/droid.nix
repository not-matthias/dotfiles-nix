{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  patchelf,
  makeWrapper,
  ripgrep,
  xdg-utils,
}: let
  version = "0.93.0";

  platforms = {
    x86_64-linux = {
      path = "linux/x64";
      hash = "sha256-XICCiOC2LtC4Cc4PrrlkGeWTn+hRXRNx5oCsMKWD158=";
    };
    aarch64-linux = {
      path = "linux/arm64";
      hash = "sha256-yQgRPbqgGqmTOPHNnQukvGMDtfrkAPbZGP9QktyBmCg=";
    };
  };

  platform =
    platforms.${stdenvNoCC.hostPlatform.system}
    or (throw "droid: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "droid";
    inherit version;

    src = fetchurl {
      url = "https://downloads.factory.ai/factory-cli/releases/${version}/${platform.path}/droid";
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

      install -Dm755 "$src" "$out/libexec/droid"

      patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
        "$out/libexec/droid"

      makeWrapper "$out/libexec/droid" "$out/bin/droid" \
        --prefix PATH : ${lib.makeBinPath [ripgrep xdg-utils]}

      runHook postInstall
    '';

    meta = with lib; {
      description = "Factory AI CLI agent for the terminal";
      homepage = "https://factory.ai";
      license = licenses.unfree;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "droid";
      platforms = builtins.attrNames platforms;
    };
  }
