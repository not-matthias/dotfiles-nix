{
  pkgs,
  lib,
  fetchFromGitHub,
  ...
}:
pkgs.stdenv.mkDerivation {
  pname = "ida-d810";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "joydo";
    repo = "d810";
    rev = "87fe12ca9cfbea5744c30546308898bf7199c073";
    hash = "sha256-vnFOXjj1NXTl9lH9Je1+57Zx4xL8JFs8WLItIljNzog=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/plugins
    cp D810.py $out/plugins/
    cp -r d810 $out/plugins/
    runHook postInstall
  '';

  passthru.pythonPackages = ps: [ps.z3-solver];

  meta = with lib; {
    description = "IDA Pro microcode deobfuscation plugin";
    homepage = "https://github.com/joydo/d810";
    license = licenses.lgpl3Only;
    platforms = platforms.all;
  };
}
