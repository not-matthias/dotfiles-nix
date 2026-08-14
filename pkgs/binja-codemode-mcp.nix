{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3Packages,
  makeWrapper,
}:
stdenvNoCC.mkDerivation {
  pname = "binja-codemode-mcp";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "akrutsinger";
    repo = "binja-codemode-mcp";
    rev = "97651d17c15c38ee779d1c4dc354053df3931bf2";
    hash = "sha256-BTXW6Pbi5Vs64JH5xul25kHdLKSL11FqDA3TSsLbSio=";
  };

  installPhase = ''
    runHook preInstall

    pluginDir=$out/lib/binaryninja/plugins/binja_codemode_mcp
    mkdir -p "$pluginDir"
    cp -r ./* "$pluginDir/"

    makeWrapper ${python3Packages.python.interpreter} $out/bin/binja-codemode-mcp \
      --add-flags "$pluginDir/bridge/mcp_bridge.py"

    runHook postInstall
  '';

  nativeBuildInputs = [makeWrapper];

  meta = {
    description = "Code execution MCP server plugin for Binary Ninja";
    homepage = "https://github.com/akrutsinger/binja-codemode-mcp";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "binja-codemode-mcp";
  };
}
