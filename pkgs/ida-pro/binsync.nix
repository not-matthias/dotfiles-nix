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

  libbs-pkg = noRuntimeCheck (
    ps.buildPythonPackage rec {
      pname = "libbs";
      version = "3.3.3";
      pyproject = true;
      src = ps.fetchPypi {
        inherit pname version;
        hash = "sha256-hYtos6MBMddRq/ijQUIAXT+2HHU7oWaNcsQC2xsN9qE=";
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
        toml
        tqdm
      ];
      doCheck = false;
      pythonImportsCheck = ["libbs"];
    }
  );

  binsync-pkg = ps.buildPythonPackage rec {
    pname = "binsync";
    version = "5.11.2";
    pyproject = true;
    src = ps.fetchPypi {
      inherit pname version;
      hash = "sha256-zZsFkxKqf6Yoc/xfBzfRrT1aXdOnXauOntmxH34YCls=";
    };
    build-system = [ps.setuptools];
    dependencies = with ps; [
      libbs-pkg
      sortedcontainers
      toml
      gitpython
      filelock
      pycparser
      ply
      prompt-toolkit
      tqdm
      wordfreq
    ];
    doCheck = false;
    pythonImportsCheck = ["binsync"];
  };
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
