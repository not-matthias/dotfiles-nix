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
    rev = "8a3de2f3b0c178fdd6f73f2f94172dfc3943e466";
    hash = "sha256-HFzG+GMriPhoMinjji+3sklQ7Nq0yRHCz/t9Re/TksU=";
  };

  npmDepsHash = "sha256-en4VPyOa58VkgZIP2nn+7YLWb0gASqntnabgYbGaJVQ=";

  postPatch = ''
    cp ${./pi-openai-server-compaction-package-lock.json} package-lock.json
    ${nodejs_22}/bin/node -e "
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      delete pkg.devDependencies;
      delete pkg.peerDependencies;
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    "
  '';

  dontNpmBuild = true;
  npmInstallFlags = ["--omit=dev" "--omit=peer" "--ignore-scripts"];

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
