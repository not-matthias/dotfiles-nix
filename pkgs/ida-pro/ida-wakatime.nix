{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation rec {
  pname = "ida-wakatime";
  version = "1.1";

  src = pkgs.fetchFromGitHub {
    owner = "es3n1n";
    repo = "ida-wakatime-py";
    rev = "v${version}";
    hash = "sha256-tUUMUgXHfhoKRbFArFeY6i1mQkvOF6bK25ROfbxiqw4=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/plugins
    cp wakatime.py $out/plugins/wakatime.py

    runHook postInstall
  '';

  meta = with lib; {
    description = "WakaTime integration for IDA Pro";
    homepage = "https://github.com/es3n1n/ida-wakatime-py";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
