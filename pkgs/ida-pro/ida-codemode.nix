{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  python313Packages,
}: let
  # ida-domain pulls in idapro only when imported outside an IDA process. The
  # GUI plugin runs inside IDA, so it short-circuits that import, but the deps
  # are still shipped so headless/other entry points resolve.
  idapro-pkg = python313Packages.buildPythonPackage rec {
    pname = "idapro";
    version = "0.0.10";
    pyproject = true;
    src = python313Packages.fetchPypi {
      inherit pname version;
      hash = "sha256-QXwDxGBdGEF+Rw9qdI45eznW1YKevTu97dkv9bkJLRE=";
    };
    build-system = [python313Packages.setuptools];
    doCheck = false;
  };

  ida-domain-pkg = python313Packages.buildPythonPackage rec {
    pname = "ida-domain";
    version = "0.5.1";
    pyproject = true;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/source/i/ida-domain/ida_domain-${version}.tar.gz";
      hash = "sha256-xJ8sQXBH2ILpVPZRtQpwmj8nkDszulM7eUqlTWU20W8=";
    };
    build-system = [python313Packages.hatchling];
    dependencies = with python313Packages; [
      idapro-pkg
      packaging
      typing-extensions
    ];
    doCheck = false;
  };
in
  stdenvNoCC.mkDerivation rec {
    pname = "ida-codemode";
    version = "0.6.1";

    src = fetchFromGitHub {
      owner = "HexRaysSA";
      repo = "ida-codemode";
      rev = "v${version}";
      hash = "sha256-gPxfRmlwoN+EYpwzXh2FncwulPYg73lFuc8ckdDMcjo=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/plugins

      # IDA plugin entry point plus the ida_codemode package it imports.
      cp ida_codemode_plugin.py $out/plugins/
      cp -r ida_codemode $out/plugins/ida_codemode

      runHook postInstall
    '';

    passthru = {
      ida-domain = ida-domain-pkg;
      pythonPackages = _ps: [ida-domain-pkg idapro-pkg];
    };

    meta = with lib; {
      description = "IDA Code Mode: compact Python execution surface over the ida-domain API";
      homepage = "https://github.com/HexRaysSA/ida-codemode";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }