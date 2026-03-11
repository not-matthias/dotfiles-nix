{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation rec {
  pname = "ida-guides";
  version = "1.3.0";

  src = pkgs.fetchzip {
    url = "https://github.com/libtero/idaguides/archive/refs/heads/main.zip";
    hash = "sha256-m9KV95DAOOAk2kpwOmd3qffj71PQYrmzZfpUt1GgSK4=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/plugins
    cp main.py $out/plugins/idaguides.py

    runHook postInstall
  '';

  meta = with lib; {
    description = "Indent guides plugin for Hex-Rays decompiler";
    homepage = "https://github.com/libtero/idaguides";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
