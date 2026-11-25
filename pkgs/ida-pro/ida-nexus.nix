{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python313Packages,
  ida-domain,
}: let
  version = "0.14.2";
  src = fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-nexus";
    rev = "v${version}";
    hash = "sha256-gz5hf6n0WL7PluCXPmn1MrzygObNZPycPaBd8LN6HDE=";
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
    dependencies = [ida-domain];

    doCheck = false;

    passthru.plugin = plugin;

    meta = with lib; {
      description = "IDA Nexus command-line tools";
      homepage = "https://github.com/HexRaysSA/ida-nexus";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  }
