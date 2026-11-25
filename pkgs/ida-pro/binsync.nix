{
  pkgs,
  lib,
  ...
}: let
  ps = pkgs.python313Packages;
  runtimeDepsCheckHook = ps.pythonRuntimeDepsCheckHook;

  # Helper to strip the runtime deps check hook from a Python package.
  noRuntimeCheck = drv:
    drv.overrideAttrs (old: {
      nativeBuildInputs = builtins.filter (x: x != runtimeDepsCheckHook) (
        old.nativeBuildInputs or []
      );
    });

  # declib 4.x works with pycparser 3.
  declib-pkg = noRuntimeCheck (
    ps.buildPythonPackage rec {
      pname = "declib";
      version = "4.5.0";
      pyproject = true;
      src = ps.fetchPypi {
        inherit pname version;
        hash = "sha256-Mz3TiZJjnrfrSY/hjCbYjqqnayCs5QTFn5Li6wvLWgc=";
      };
      build-system = [ps.setuptools];
      dependencies = with ps; [
        filelock
        networkx
        platformdirs
        ply
        prompt-toolkit
        psutil
        pycparser
        pyghidra
        setuptools
        toml
        tqdm
      ];
      doCheck = false;
      pythonImportsCheck = ["declib"];
    }
  );

  binsync-pkg = noRuntimeCheck (
    ps.buildPythonPackage rec {
      pname = "binsync";
      version = "5.15.4";
      pyproject = true;
      src = ps.fetchPypi {
        inherit pname version;
        hash = "sha256-53insWctR7c9YD3cVRYHHm1RXSoZnAw9CzH5k6q4tOI=";
      };
      build-system = [ps.setuptools];
      dependencies = with ps; [
        declib-pkg
        sortedcontainers
        toml
        gitpython
        filelock
        ply
        prompt-toolkit
        requests
        tqdm
        wordfreq
      ];
      doCheck = false;
      pythonImportsCheck = ["binsync"];
    }
  );
in
  pkgs.stdenv.mkDerivation {
    pname = "binsync-ida";
    version = binsync-pkg.version;

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/plugins

      cp ${binsync-pkg}/${pkgs.python313.sitePackages}/binsync/binsync_plugin.py \
        $out/plugins/binsync_plugin.py

      runHook postInstall
    '';

    passthru.pythonPackages = _ps: [binsync-pkg];

    meta = with lib; {
      description = "BinSync collaborative reversing plugin for IDA Pro";
      homepage = "https://github.com/binsync/binsync";
      license = licenses.bsd2;
      platforms = platforms.all;
    };
  }
