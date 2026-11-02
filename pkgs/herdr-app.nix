{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  herdr-core,
  libxcb,
  libxkbcommon,
  libglvnd,
  vulkan-loader,
  wayland,
}: let
  version = "0.1.11";
  assets = {
    x86_64-linux = {
      target = "linux-x86_64";
      hash = "sha256-Ro/zFqJvxMLGOPEMWNLeNTyCXKxNhG+iVMYSlBQXRKM=";
    };
    aarch64-linux = {
      target = "linux-aarch64";
      hash = "sha256-Bx/25znj5YGQw3hEFoQUXXIlRr+MrXBdRPBL871SAig=";
    };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "Herdr app ${version} is not available for ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "herdr-app";
    inherit version;
    src = fetchurl {
      url = "https://releases.herdr.dev/app/${version}/herdr-app-${asset.target}.tar.gz";
      inherit (asset) hash;
    };

    nativeBuildInputs = [autoPatchelfHook makeWrapper];
    buildInputs = [libxcb libxkbcommon stdenv.cc.cc.lib];
    # GPUI loads the rendering and display backends with dlopen.
    runtimeDependencies = map lib.getLib [libglvnd vulkan-loader wayland];
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 herdr-app "$out/bin/herdr-app"
      # Keeping the icon in the desktop icon tree makes updates Nix-managed.
      install -Dm644 herdr-app.svg "$out/share/icons/hicolor/scalable/apps/herdr-app.svg"
      wrapProgram "$out/bin/herdr-app" \
        --prefix PATH : ${lib.makeBinPath [herdr-core]}
      runHook postInstall
    '';

    meta = {
      description = "Terminals and coding agents that keep running";
      homepage = "https://github.com/herdrdev/herdr-app";
      license = lib.licenses.asl20;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames assets;
      mainProgram = "herdr-app";
    };
  }
