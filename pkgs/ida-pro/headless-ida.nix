{
  pkgs,
  lib,
  ...
}: let
  ps = pkgs.python313Packages;

  headless-ida-pkg = ps.buildPythonPackage rec {
    pname = "headless-ida";
    version = "0.6.7";
    pyproject = true;
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/h/headless-ida/headless_ida-${version}.tar.gz";
      hash = "sha256-ud0+n+qnxGEI9s7HeEX7L0kIz7YInVq57qTVuul6/xk=";
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
