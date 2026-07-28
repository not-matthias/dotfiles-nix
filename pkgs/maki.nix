{
  lib,
  stdenvNoCC,
  fetchzip,
}: let
  version = "0.4.4";
in
  stdenvNoCC.mkDerivation {
    pname = "maki";
    inherit version;

    # Static-pie musl binary; no patchelf/interpreter work needed.
    # Tarball contains `maki` at its root (no top-level dir), so stripRoot=false.
    src = fetchzip {
      url = "https://github.com/tontinton/maki/releases/download/v${version}/maki-v${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-MN3i1O3X3AKDOBrObR5Z86vnPYP7eVQCEYkDwtpNTio=";
      stripRoot = false;
    };

    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src/maki $out/bin/maki
      runHook postInstall
    '';

    meta = {
      description = "Efficient AI coding agent — native Rust TUI with file indexing and sandboxed tool chaining";
      homepage = "https://maki.sh";
      downloadPage = "https://github.com/tontinton/maki/releases";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "maki";
    };
  }
