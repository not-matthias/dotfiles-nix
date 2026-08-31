{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "ida-mcp";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-mcp";
    rev = "a36a51c9d68d7e8822348e057b1e82c633f2b8dd";
    hash = "sha256-j4jz/kGLTB/9eZtlF/Eb57dIar3U2wevf+GsrmQKCpg=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/plugins
    cp ida_mcp_plugin.py $out/plugins/
    cp -r ida_mcp $out/plugins/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Official Hex-Rays IDA MCP plugin";
    homepage = "https://github.com/HexRaysSA/ida-mcp";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
