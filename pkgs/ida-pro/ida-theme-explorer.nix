{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation {
  pname = "ida-theme-explorer";
  version = "1.0.2";

  src = pkgs.fetchFromGitHub {
    owner = "kevinmuoz";
    repo = "ida-theme-explorer";
    rev = "v1.0.2";
    hash = "sha256-jLtX1l7GhXaiNlOiehgFYI4VQ2SgA5QaKVQu1wfvb9w=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/plugins
    cp -r * $out/plugins/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Install and browse 100+ community themes for IDA Pro";
    homepage = "https://github.com/kevinmuoz/ida-theme-explorer";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
