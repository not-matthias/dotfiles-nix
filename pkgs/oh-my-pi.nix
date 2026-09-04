{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
}:
# Standalone `bun build --compile` binary that bundles its own Bun runtime,
# so it sidesteps the nixpkgs Bun version (the npm/source install of `omp`
# refuses to start when the system Bun is older than its MIN_BUN_VERSION).
stdenv.mkDerivation rec {
  pname = "oh-my-pi";
  version = "18.1.10";
  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
    hash = "sha256-6R1VmO5H4dQJn9hobcn2HJt1Xy6gd9Xxd0q6EHIyH54=";
  };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/omp
    runHook postInstall
  '';

  # ONNX inference workers load prebuilt native addons from the user cache.
  # Their dependencies are not covered by the bundled binary's RPATH, so OMP
  # needs the Nix C++ library path when it constructs those worker environments.
  postFixup = ''
    wrapProgram "$out/bin/omp" \
      --set-default OMP_NATIVE_LIBRARY_PATH "${lib.makeLibraryPath [stdenv.cc.cc.lib]}"
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
