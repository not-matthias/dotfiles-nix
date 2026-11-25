{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "ida-mcp";
  version = "20261028.0.3";

  src = fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-mcp";
    rev = "v20261028.0.3";
    hash = "sha256-AoCC/MFOsXXbIK0wqe25cnKYVV/Z9g5uKHnZqlL/RPY=";
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
