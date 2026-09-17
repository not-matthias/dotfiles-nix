{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  mold,
  glib,
  wayland,
  libxkbcommon,
  vulkan-loader,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
}:
rustPlatform.buildRustPackage {
  pname = "choosr";
  version = "1.0.0-unstable-2026-09-16";

  src = fetchFromGitHub {
    owner = "xaknick";
    repo = "choosr";
    rev = "1e6b47774b8bd02d1f4135305fc5b7ac61e675a9";
    hash = "sha256-dVQxM29cMSq6ZGXMYEARvjQc1mFCzGdz7owCjG+frJc=";
  };

  cargoHash = "sha256-t2/9aIrQy8BYYjNhY204wPz42kj8ok/bp7FU28CPbqM=";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    mold
  ];
  buildInputs = [
    wayland
    libxkbcommon
    vulkan-loader
    libx11
    libxcursor
    libxi
    libxrandr
  ];

  postFixup = ''
    wrapProgram $out/bin/choosr --prefix PATH : ${lib.makeBinPath [glib]}
  '';

  meta = {
    description = "Rule-based browser chooser for Linux";
    homepage = "https://github.com/xaknick/choosr";
    license = lib.licenses.mit;
    mainProgram = "choosr";
    platforms = lib.platforms.linux;
  };
}
