{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-goal";
  version = "0.0.2-unstable-2026-05-28";

  # Selected implementation:
  # https://github.com/baggiiiie/pi-stuff/blob/main/packages/goal/README.md
  # Alternatives compared:
  # https://github.com/ogulcancelik/pi-extensions/tree/main/packages/pi-goal
  # https://github.com/ramarivera/pi-goal
  # https://github.com/PurpleMyst/pi-goal
  src = fetchFromGitHub {
    owner = "baggiiiie";
    repo = "pi-stuff";
    rev = "ee26e133e0a5c55a6cc818b8b012cfabfcf4b0f7";
    hash = "sha256-3uMwZ0uyoWIOiHedynzzpJsywE5TjNOgp0B4dl7TKR4=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R packages/goal/. $out/
    runHook postInstall
  '';

  meta = {
    description = "Codex-style persisted goals for pi coding agent sessions";
    homepage = "https://github.com/baggiiiie/pi-stuff/blob/main/packages/goal/README.md";
    license = lib.licenses.mit;
  };
}
