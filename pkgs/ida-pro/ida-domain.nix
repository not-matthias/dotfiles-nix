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
    version = "0.6.0";
    pyproject = true;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/9d/97/56f3dacfe13414559a9b428a152375b79f302a432ab009aac33acb109ff1/ida_domain-0.6.0.tar.gz";
      hash = "sha256-rXsfAVLLj8ShBNR6/o+7c2JKhHUQ0dLsLX8mhoAJ27I=";
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
