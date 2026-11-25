{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "binja-codemode-mcp";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "akrutsinger";
    repo = "binja-codemode-mcp";
    rev = "50a3ed3a7a10a1479f27dc89233ace5f99eebb2a";
    hash = "sha256-4aYx5khRwvdelrNN6GCHdPv0jnATb1XzUFH2pCdvMG8=";
  };

  # The plugin serves MCP itself over Streamable HTTP at
  # http://127.0.0.1:42069/mcp (bearer token); there is no bridge script.
  installPhase = ''
    runHook preInstall

    pluginDir=$out/lib/binaryninja/plugins/binja_codemode_mcp
    mkdir -p "$pluginDir"
    cp -r ./* "$pluginDir/"

    runHook postInstall
  '';

  meta = {
    description = "Code execution MCP server plugin for Binary Ninja";
    homepage = "https://github.com/akrutsinger/binja-codemode-mcp";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
