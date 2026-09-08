{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  python313Packages,
  ida-domain,
}: let
  version = "0.9.1";
  src = fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-nexus";
    rev = "abac0b389fe280e66f17f74a17708ee38dc0bb0a";
    hash = "sha256-7Q/nYxZzXj7GgukYbN2fN+RIX8Kjzlbjf3xs5O5Qmw0=";
  };

  zeromcp = python313Packages.buildPythonPackage {
    pname = "zeromcp";
    version = "1.9.0";
    pyproject = true;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/08/1f/97c16db209141a5155255ea315af5f85d623d25b9ba092471240ad74ef14/zeromcp-1.9.0.tar.gz";
      hash = "sha256-Qbz+dtgtm8sUlzm/ie/XEh+hrIGMIVVCFsnMcik+bMk=";
    };
    build-system = [python313Packages.hatchling];
    doCheck = false;
  };

  plugin = stdenvNoCC.mkDerivation {
    pname = "ida-nexus-plugin";
    inherit version src;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/plugins
      cp ida_nexus_plugin.py $out/plugins/
      cp -r ida_nexus $out/plugins/
    '';
  };
in
  python313Packages.buildPythonPackage {
    pname = "ida-nexus";
    inherit version src;

    pyproject = true;
    build-system = [python313Packages.hatchling];
    dependencies = [ida-domain python313Packages.packaging zeromcp];

    doCheck = false;

    passthru.plugin = plugin;

    meta = with lib; {
      description = "IDA Nexus command-line tools";
      homepage = "https://github.com/HexRaysSA/ida-nexus";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  }
