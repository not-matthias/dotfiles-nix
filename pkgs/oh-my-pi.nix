{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
# Standalone `bun build --compile` binary that bundles its own Bun runtime,
# so it sidesteps the nixpkgs Bun version (the npm/source install of `omp`
# refuses to start when the system Bun is older than its MIN_BUN_VERSION).
stdenv.mkDerivation rec {
  pname = "oh-my-pi";
  version = "15.11.0";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
    hash = "sha256-ekV9B6ql5iyjyKVa1ygzzd5G8oECych7EVf2BprYo08=";
  };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/omp
    runHook postInstall
  '';

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management (oh-my-pi)";
    homepage = "https://omp.sh";
    downloadPage = "https://github.com/can1357/oh-my-pi/releases";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "omp";
  };
}
