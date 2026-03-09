{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation {
  pname = "ida-pro-mcp";
  version = "2.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "mrexodia";
    repo = "ida-pro-mcp";
    rev = "main";
    hash = "sha256-KRhirCNmoce6nn8z0PDiXTBi1Urw47a2rkdCHGeKvrY=";
  };

  # No build step needed -- just copy plugin files into the IDA directory layout.
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/plugins

    # The IDA plugin entry point.
    cp src/ida_pro_mcp/ida_mcp.py $out/plugins/

    # The core ida_mcp package (imported by the plugin at runtime).
    cp -r src/ida_pro_mcp/ida_mcp $out/plugins/ida_mcp

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI-powered reverse engineering assistant bridging IDA Pro with LLMs via MCP";
    homepage = "https://github.com/mrexodia/ida-pro-mcp";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
