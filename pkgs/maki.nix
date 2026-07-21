{
  lib,
  stdenvNoCC,
  fetchzip,
}: let
  version = "0.4.1";
in
  stdenvNoCC.mkDerivation {
    pname = "maki";
    inherit version;

    # Static-pie musl binary; no patchelf/interpreter work needed.
    # Tarball contains `maki` at its root (no top-level dir), so stripRoot=false.
    src = fetchzip {
      url = "https://github.com/tontinton/maki/releases/download/v${version}/maki-v${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-oIuoyGc14oK4i2sG7q+E0/1auHQ0ccomAZO28Cqg0C4=";
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
