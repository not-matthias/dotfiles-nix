{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation rec {
  pname = "aw-server-rust";
  version = "0.14.1";

  src = fetchurl {
    url = "https://github.com/ActivityWatch/activitywatch/releases/download/v${version}/activitywatch-v${version}-linux-x86_64.zip";
    hash = "sha256-IRUUqJEsCjmajHBIEBtpngov7bXoG17SJDBNXI4JHyo=";
  };

  dontUnpack = true;
  dontStrip = true;
  nativeBuildInputs = [unzip autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    unzip -j "$src" \
      activitywatch/aw-server-rust/aw-server-rust \
      activitywatch/aw-server-rust/aw-sync
    install -Dm755 aw-server-rust "$out/bin/aw-server"
    install -Dm755 aw-sync "$out/bin/aw-sync"
    runHook postInstall
  '';

  meta = {
    description = "ActivityWatch Rust server and sync client from the official release bundle";
    homepage = "https://github.com/ActivityWatch/aw-server-rust";
    changelog = "https://github.com/ActivityWatch/activitywatch/releases/tag/v${version}";
    license = lib.licenses.mpl20;
    platforms = ["x86_64-linux"];
    mainProgram = "aw-server";
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
  };
}
