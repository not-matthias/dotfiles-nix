{
  lib,
  rustPlatform,
  stdenv,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "helix-file-watcher";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = "helix-file-watcher";
    rev = "8cd0726da47be4a1011c3246ff308c1dfefda9d1";
    hash = "sha256-auqS4wcJGCUJXzRVj4neQLJnqErvty3+3shfq5DU/pg=";
  };

  cargoHash = "sha256-RhxKQSydcY48/aWZGPbJe6pFrKptynMV35BQSD16tXo=";

  installPhase = ''
    runHook preInstall
    install -Dm644 cog.scm $out/share/steel/cogs/helix-file-watcher/cog.scm
    install -Dm644 file-watcher.scm $out/share/steel/cogs/helix-file-watcher/file-watcher.scm
    install -Dm644 helix-file-watcher.scm $out/share/steel/cogs/helix-file-watcher/helix-file-watcher.scm
    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTarget}/release/libhelix_file_watcher.so \
      $out/lib/libhelix_file_watcher.so
    runHook postInstall
  '';

  meta = {
    description = "Low-overhead external file watcher for Helix Steel";
    homepage = "https://github.com/mattwparas/helix-file-watcher";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
