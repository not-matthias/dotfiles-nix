{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-openai-server-compaction";
  version = "0.1.0";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "algal";
    repo = "pi-openai-server-compaction";
    rev = "fcc4cd34f714df1667dcdde59b681fc9cf656a7c";
    hash = "sha256-1f3gHfN3q7yGHAROuP+PKGv4jjENa8wEKSyAyL0SKoM=";
  };

  npmDepsHash = "sha256-x0HU4SkQQqfcW2/Yh2oP27YUyVfv2Xx7quS87FOyHwA=";

  postPatch = ''
    cp ${./pi-openai-server-compaction-package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;
  npmInstallFlags = ["--omit=dev" "--ignore-scripts"];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';

  meta = {
    description = "OpenAI-compatible server compaction extension for pi";
    homepage = "https://github.com/algal/pi-openai-server-compaction";
    license.spdxId = "MIT";
  };
}
