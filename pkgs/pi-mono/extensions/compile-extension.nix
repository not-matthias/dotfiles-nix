# Pre-compile a pi extension's TypeScript entrypoints to JavaScript using esbuild.
# This eliminates jiti transpilation at runtime, significantly improving startup time.
#
# Usage:
#   compileExtension { src = <extension-source>; }
#   compileExtension { src = <extension-source>; entrypoints = ["./src/index.ts"]; }
#
# If entrypoints is omitted, they are auto-detected from package.json's pi.extensions
# field, falling back to index.ts at root.
{
  stdenvNoCC,
  esbuild,
  nodejs_22,
  src,
  entrypoints ? null,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-extension-compiled";
  version = "1.0.0";

  inherit src;

  nativeBuildInputs = [esbuild nodejs_22];

  buildPhase = ''
    runHook preBuild

    # Detect entrypoints from package.json or use provided ones
    entrypoints=""
    if [ -n "${toString entrypoints}" ]; then
      entrypoints="${builtins.concatStringsSep " " (
      if entrypoints != null
      then entrypoints
      else []
    )}"
    else
      if [ -f package.json ]; then
        entrypoints=$(${nodejs_22}/bin/node -e '
          const pkg = JSON.parse(require("fs").readFileSync("package.json", "utf8"));
          const entries = pkg.pi?.extensions || [];
          const tsEntries = entries.filter(e => e.endsWith(".ts"));
          if (tsEntries.length > 0) {
            console.log(tsEntries.join(" "));
          } else if (require("fs").existsSync("index.ts")) {
            console.log("./index.ts");
          }
        ')
      elif [ -f index.ts ]; then
        entrypoints="./index.ts"
      fi
    fi

    if [ -z "$entrypoints" ]; then
      echo "No TypeScript entrypoints found, skipping compilation"
    else
      for entry in $entrypoints; do
        if [ ! -f "$entry" ]; then
          echo "WARNING: entrypoint $entry not found, skipping"
          continue
        fi

        # Compute output path: replace .ts with .js, put in dist/ relative dir
        outfile=$(echo "$entry" | sed 's|\.ts$|.js|')
        outdir=$(dirname "$outfile")
        mkdir -p "$outdir"

        echo "Compiling $entry -> $outfile"
        esbuild "$entry" \
          --bundle \
          --outfile="$outfile" \
          --platform=node \
          --format=esm \
          --target=node22 \
          '--external:@earendil-works/*' \
          '--external:@mariozechner/*' \
          '--external:@anthropic-ai/*' \
          '--external:@sinclair/typebox' \
          '--external:@sinclair/typebox/*' \
          '--external:typebox' \
          '--external:typebox/*' \
          '--external:diff'
      done
    fi

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R . $out/

    # Remove .ts source files so pi's auto-discovery loads the compiled .js
    # instead of jiti-transpiling the .ts at runtime
    find $out -name '*.ts' -not -path '*/node_modules/*' -delete

    # Patch package.json pi.extensions to point to compiled .js files
    if [ -f $out/package.json ]; then
      ${nodejs_22}/bin/node -e '
        const fs = require("fs");
        const path = require("path");
        const pkgPath = process.env.out + "/package.json";
        const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
        if (pkg.pi?.extensions) {
          pkg.pi.extensions = pkg.pi.extensions.map(e => {
            const jsPath = e.replace(/\.ts$/, ".js");
            if (fs.existsSync(path.join(process.env.out, jsPath))) {
              return jsPath;
            }
            return e;
          });
          fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
        } else {
          // Auto-discovered extension: if we compiled index.ts, add pi.extensions
          const indexJs = path.join(process.env.out, "index.js");
          const indexTs = path.join(process.env.out, "index.ts");
          if (fs.existsSync(indexJs) && fs.existsSync(indexTs)) {
            pkg.pi = pkg.pi || {};
            pkg.pi.extensions = ["./index.js"];
            fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
          }
        }
      '
    fi

    runHook postInstall
  '';
}
