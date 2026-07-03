# Paperclip — open-source AI agent orchestration platform
# https://github.com/paperclipai/paperclip
#
# This packages the paperclipai CLI which bundles the server + embedded postgres.
# Run with: paperclipai start
{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  pnpm_9,
  python3,
  postgresql_16,
  makeWrapper,
  autoPatchelfHook,
  glibc,
}: let
  pname = "paperclip";
  version = "2026.626.0";

  src = fetchFromGitHub {
    owner = "paperclipai";
    repo = "paperclip";
    tag = "v${version}";
    hash = "sha256-0NHPGXICWOGfK1mL1Lv2Pa7XPQEbGXWx8vvAHZkjnWo=";
  };

  pnpm = pnpm_9;
in
  buildNpmPackage {
    inherit pname version src;

    npmConfigHook = pnpm.configHook;

    npmDeps = null;
    pnpmDeps = pnpm.fetchDeps {
      inherit pname version src;
      fetcherVersion = 2;
      hash = "sha256-0B6rpc7fiMY91ZGQoVcNgAkUUKzgUeBAfAoV4xwrgPU=";
    };

    nativeBuildInputs = [
      nodejs_22
      makeWrapper
      python3 # needed for node-gyp native addons
      autoPatchelfHook
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      glibc
    ];

    # embedded-postgres ships platform-specific binaries that need patching
    autoPatchelfIgnoreMissingDeps = true;

    env = {
      ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    };

    # Set before configurePhase because pnpmConfigHook runs install there.
    preConfigure = ''
      echo "shamefully-hoist=true" >> .npmrc
    '';

    buildPhase = ''
      runHook preBuild

      pnpm -r build

      # Workspace packages export src/ (TypeScript) in development;
      # publishConfig switches to dist/ for npm. Apply it locally so
      # Node resolves compiled output at runtime.
      node -e 'const fs=require("fs"),{join}=require("path"),ex=p=>fs.existsSync(p);function patch(p){if(!ex(p))return;const j=JSON.parse(fs.readFileSync(p,"utf8"));const pub=j.publishConfig||{};let c=false;for(const k of["exports","main","types","module"]){if(pub[k]){j[k]=pub[k];c=true;}}if(c)fs.writeFileSync(p,JSON.stringify(j,null,2)+"\n");}for(const d of["packages","packages/adapters","packages/plugins"]){if(!ex(d))continue;for(const e of fs.readdirSync(d)){const p=join(d,e);if(fs.statSync(p).isDirectory())patch(join(p,"package.json"));}}patch("server/package.json");patch("cli/package.json");patch("package.json");'

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/paperclip
      cp -r . $out/lib/paperclip/

      # embedded-postgres bundles native libs as libfoo.so.X.Y but
      # creates libfoo.so.X symlinks at runtime; the store is read-only.
      EP_LIB="$out/lib/paperclip/node_modules/.pnpm/embedded-postgres"*/node_modules/@embedded-postgres/linux-x64/native/lib
      for libdir in $EP_LIB; do
        for f in "$libdir"/lib*.so.*.*; do
          base=$(basename "$f")
          major=$(echo "$base" | sed 's/\(.*\.so\.[0-9]*\)\..*/\1/')
          [ ! -e "$libdir/$major" ] && ln -s "$base" "$libdir/$major"
        done
      done

      mkdir -p $out/bin
      makeWrapper ${nodejs_22}/bin/node $out/bin/paperclipai \
        --add-flags "$out/lib/paperclip/cli/dist/index.js" \
        --prefix PATH : ${lib.makeBinPath [postgresql_16]} \
        --set NODE_PATH "$out/lib/paperclip/node_modules"

      runHook postInstall
    '';

    meta = {
      description = "Open-source orchestration for AI agent teams";
      homepage = "https://github.com/paperclipai/paperclip";
      license = lib.licenses.mit;
      mainProgram = "paperclipai";
      platforms = lib.platforms.linux;
    };
  }
