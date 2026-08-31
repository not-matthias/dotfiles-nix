{
  lib,
  fetchurl,
  python313Packages,
}: let
  idapro = python313Packages.buildPythonPackage {
    pname = "idapro";
    version = "0.0.10";
    pyproject = true;
    src = python313Packages.fetchPypi {
      pname = "idapro";
      version = "0.0.10";
      hash = "sha256-QXwDxGBdGEF+Rw9qdI45eznW1YKevTu97dkv9bkJLRE=";
    };
    build-system = [python313Packages.setuptools];
    doCheck = false;
  };
in
  python313Packages.buildPythonPackage {
    pname = "ida-domain";
    version = "0.5.1";
    pyproject = true;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/80/34/be087d3ea1c3a6573e0660cb5b40f0c4ade9ae5772cf1c5d98d52472d28b/ida_domain-0.5.1.tar.gz";
      hash = "sha256-xJ8sQXBH2ILpVPZRtQpwmj8nkDszulM7eUqlTWU20W8=";
    };
    build-system = [python313Packages.hatchling];
    dependencies = with python313Packages; [
      idapro
      packaging
      typing-extensions
    ];
    doCheck = false;

    meta = with lib; {
      description = "Official Hex-Rays IDA Domain Python API";
      homepage = "https://github.com/HexRaysSA/ida-domain";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  }
