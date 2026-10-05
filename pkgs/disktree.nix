{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  libxkbcommon,
  libxcb,
  wayland,
  vulkan-loader,
  stdenv,
}:
stdenvNoCC.mkDerivation rec {
  pname = "disktree";
  version = "0.11.0";
  src = fetchurl {
    url = "https://github.com/tobi/disktree/releases/download/v${version}/disktree-${version}-x86_64-linux.tar.gz";
    hash = "sha256-fnWvoig8i0+SkNUurb/ADZ8UwTrtLSJMzfD3gm/MBbI=";
  };
  sourceRoot = "disktree-${version}-x86_64-linux";
  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [libxkbcommon libxcb wayland vulkan-loader stdenv.cc.cc.lib];
  runtimeDependencies = [wayland vulkan-loader];
  installPhase = ''
    runHook preInstall
    install -Dm755 disktree $out/bin/disktree
    install -Dm644 disktree.svg $out/share/icons/hicolor/scalable/apps/disktree.svg
    install -Dm644 disktree.desktop.in $out/share/applications/disktree.desktop
    substituteInPlace $out/share/applications/disktree.desktop \
      --replace-fail '@BINDIR@' "$out/bin" \
      --replace-fail '@VERSION@' '${version}'
    runHook postInstall
  '';
  meta = {
    description = "A treemap for finding and removing what fills your disk";
    homepage = "https://github.com/tobi/disktree";
    license = lib.licenses.mit;
    mainProgram = "disktree";
    platforms = ["x86_64-linux"];
  };
}
