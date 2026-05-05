{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-goal";
  version = "0.0.1-unstable-2026-05-03";

  # Selected implementation:
  # https://github.com/baggiiiie/pi-stuff/blob/main/packages/goal/README.md
  # Alternatives compared:
  # https://github.com/ogulcancelik/pi-extensions/tree/main/packages/pi-goal
  # https://github.com/ramarivera/pi-goal
  # https://github.com/PurpleMyst/pi-goal
  src = fetchFromGitHub {
    owner = "baggiiiie";
    repo = "pi-stuff";
    rev = "7ede521226d332ba87bffc7b0a8b0ea804b81827";
    hash = "sha256-u/FaJi0c7PxN6XKH29oGolk524WuNx4nzW+YRqaZ3P4=";
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
