{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3Packages,
}:
stdenvNoCC.mkDerivation {
  pname = "binja-headless";
  version = "0.1.0-unstable-2025-02-13";

  src = fetchFromGitHub {
    owner = "hugsy";
    repo = "binja-headless";
    rev = "e6ab5adb2188efd27c3485fd014125c8b9a2648b";
    hash = "sha256-JBW4iUwK1LqF9OuohgbX4tN5mnUsCj6e7KLZjijCnxc=";
  };

  installPhase = ''
    runHook preInstall

    pluginDir=$out/lib/binaryninja/plugins/binja-headless
    mkdir -p "$pluginDir"
    cp __init__.py constants.py helpers.py plugin.json server.py "$pluginDir/"
    ln -s ${python3Packages.rpyc}/${python3Packages.python.sitePackages}/rpyc "$pluginDir/rpyc"
    ln -s ${python3Packages.plumbum}/${python3Packages.python.sitePackages}/plumbum "$pluginDir/plumbum"

    runHook postInstall
  '';

  meta = {
    description = "Remote headless control plugin for Binary Ninja";
    homepage = "https://github.com/hugsy/binja-headless";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
