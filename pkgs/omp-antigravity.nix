{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  bun,
}: let
  dependencies = [
    {
      name = "@agentclientprotocol/sdk";
      version = "2.5.0";
      hash = "sha512-MFlXeIuwN6nZSK45SAsSnVjbLgQ2r4fnthoF1lQoGJP3PdaPRpOZeCF2Dds8S4cN8yZP5QbxB1bkJccGskmcYw==";
    }
    {
      name = "@modelcontextprotocol/server";
      version = "2.4.0";
      hash = "sha512-rgR9yxSaAJ+bcsi/XroT/S2AfPiIWloXAnrdfYSCms9ivVju0ishu/wW0J21Ho6+ZOR1r7RyeRbjiRuF87ix5Q==";
    }
    {
      name = "@modelcontextprotocol/core";
      version = "2.4.0";
      hash = "sha512-z8QBKqdfXLPzkLQuG4xp8hrVEMm1PZ1IgxMN2sMbJiFiAKOWXnAzogXn2W4aqIBlP1ea6U5yiqVquvUNM1Cj6Q==";
    }
    {
      name = "zod";
      version = "4.6.7";
      hash = "sha512-g8W2D2kU6a8untc053fX1uVBKzM7yqAxW/3zwk83+6RyF2+SKOuV+c0wBDhUwzV1PaGapmZH+rmcUzPf+3CGwg==";
    }
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "omp-antigravity";
    version = "0.1.0";
    src = fetchFromGitHub {
      owner = "alphastorm";
      repo = "omp-antigravity";
      rev = "f0a8720f838e135148211aa7b3aa8a4d4daa1aab";
      hash = "sha256-teDvdKyvKHPReC2x8P429bdil7R1jNZtVXt3jg7Jl+s=";
    };
    nativeBuildInputs = [bun];
    # OMP 18.20 reserves antigravity-acp as a built-in API name.
    postPatch = ''
      substituteInPlace src/index.ts \
        --replace-fail 'api: PROVIDER,' 'api: "omp-antigravity-acp",'
    '';
    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      ${lib.concatMapStringsSep "\n" (dep: let
          archive = fetchurl {
            url = "https://registry.npmjs.org/${dep.name}/-/${baseNameOf dep.name}-${dep.version}.tgz";
            inherit (dep) hash;
          };
        in ''
          mkdir -p node_modules/${dep.name}
          tar -xzf ${archive} -C node_modules/${dep.name} --strip-components=1
        '')
        dependencies}
      bun build src/index.ts src/doctor.ts --target=bun --outdir=dist --external '@oh-my-pi/*'
      bun -e 'const p = await Bun.file("package.json").json(); p.omp.extensions = ["./dist/index.js"]; delete p.dependencies; delete p.devDependencies; await Bun.write("package.json", JSON.stringify(p, null, 2));'
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist package.json LICENSE NOTICE.md $out/
      runHook postInstall
    '';
    meta = {
      description = "Oh My Pi provider using the official Antigravity CLI over ACP";
      homepage = "https://github.com/alphastorm/omp-antigravity";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  }
