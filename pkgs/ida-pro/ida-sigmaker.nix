{
  pkgs,
  lib,
  ...
}: let
  version = "v1.6.0";
  src = pkgs.fetchurl {
    url = "https://github.com/mahmoudimus/ida-sigmaker/releases/download/${version}/sigmaker.py";
    sha256 = "pe5kEdihe7imcb4rRtsy0kJjEYmcRzlEQ0xKJ3zih6g=";
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "ida-sigmaker";
    inherit version;

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/plugins
      cp ${src} $out/plugins/sigmaker.py

      runHook postInstall
    '';

    meta = with lib; {
      description = "Cross-platform signature maker plugin for IDA Pro 9.0+";
      homepage = "https://github.com/mahmoudimus/ida-sigmaker";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }
