{
  pkgs,
  lib,
  ...
}: let
  ps = pkgs.python313Packages;

  headless-ida-pkg = ps.buildPythonPackage rec {
    pname = "headless-ida";
    version = "0.6.8";
    pyproject = true;
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/h/headless-ida/headless_ida-${version}.tar.gz";
      hash = "sha256-0Ws3Zik+CXwvOdyrTLhicVC6c8scp9hIp180/CsxF7Y=";
    };
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace 'license = {file = "LICENSE"}' 'license = "MIT"'
    '';
    build-system = [ps.setuptools ps.setuptools-scm];
    dependencies = with ps; [
      rpyc
    ];
    doCheck = false;
    pythonImportsCheck = ["headless_ida"];
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "headless-ida";
    version = headless-ida-pkg.version;

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out

      runHook postInstall
    '';

    passthru.pythonPackages = _ps: [headless-ida-pkg];

    meta = with lib; {
      description = "Run IDA scripts headlessly";
      homepage = "https://github.com/DennyDai/headless-ida";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }
