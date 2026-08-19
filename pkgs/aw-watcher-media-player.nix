{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  dbus,
  openssl,
}:
rustPlatform.buildRustPackage rec {
  pname = "aw-watcher-media-player";
  version = "1.1.4";

  src = fetchFromGitHub {
    owner = "2e3s";
    repo = "aw-watcher-media-player";
    tag = "v${version}";
    hash = "sha256-DjoalKlnhUWEmun57G17/gtqifo3arcbkEw/vMVNWD0=";
  };

  cargoHash = "sha256-057Yjxac7BDb+7nohj51biUPHT1LN9iICihzp5cziWA=";

  nativeBuildInputs = [pkg-config];
  buildInputs = [dbus openssl];

  postInstall = ''
    install -Dm644 visualization/index.html \
      $out/share/aw-watcher-media-player/visualization/index.html
  '';

  meta = {
    description = "ActivityWatch watcher reporting the currently playing media (MPRIS on Linux)";
    homepage = "https://github.com/2e3s/aw-watcher-media-player";
    license = lib.licenses.mpl20;
    mainProgram = "aw-watcher-media-player";
    platforms = lib.platforms.linux;
  };
}
