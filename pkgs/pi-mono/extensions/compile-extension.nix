# Pre-compile a pi extension's TypeScript entrypoints to JavaScript using esbuild.
# Runtime-loaded helper modules retain their original paths for Pi's Jiti loader.
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

    entrypoints=$(${nodejs_22}/bin/node <<'EOF'
      const fs = require("fs");
      const path = require("path");
      const pkg = fs.existsSync("package.json")
        ? JSON.parse(fs.readFileSync("package.json", "utf8"))
        : { private: true, type: "module" };
      const hostPackages = new Set(["typebox", "@sinclair/typebox"]);
      for (const name of Object.keys(pkg.dependencies || {})) {
        if (!hostPackages.has(name)) continue;
        delete pkg.dependencies[name];
        pkg.peerDependencies = { ...pkg.peerDependencies, [name]: "*" };
        fs.rmSync(path.join("node_modules", name), { recursive: true, force: true });
      }
      const declared = ${builtins.toJSON entrypoints} ?? pkg.pi?.extensions ??
        (fs.existsSync("index.ts") ? ["./index.ts"] : fs.existsSync("index.js") ? ["./index.js"] : []);
      const entries = [];
      const isExtension = name => /\.(ts|js)$/.test(name) && !/\.(d|test|spec)\.ts$/.test(name);
      for (const entry of declared) {
        if (!fs.existsSync(entry)) throw new Error(`Declared Pi extension entrypoint not found: ''${entry}`);
        if (fs.statSync(entry).isDirectory()) {
          for (const child of fs.readdirSync(entry, { withFileTypes: true })) {
            const childPath = path.join(entry, child.name);
            if (child.isFile() && isExtension(child.name)) {
              entries.push(childPath);
            } else if (child.isDirectory()) {
              const index = ["index.ts", "index.js"].map(name => path.join(childPath, name)).find(fs.existsSync);
              if (index) entries.push(index);
            }
          }
        } else if (isExtension(entry)) {
          entries.push(entry);
        } else {
          throw new Error(`Unsupported Pi extension entrypoint: ''${entry}`);
        }
      }
      const uniqueEntries = [...new Set(entries)];
      if (declared.length && !uniqueEntries.length) throw new Error("Declared Pi extension directories contain no entrypoints");
      if (uniqueEntries.length) {
        pkg.pi = pkg.pi || {};
        pkg.pi.extensions = uniqueEntries.map(entry => entry.replace(/\.ts$/, ".js"));
        fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));
      }
      console.log(uniqueEntries.filter(entry => entry.endsWith(".ts")).join("\n"));
    EOF
    )

    while IFS= read -r entry; do
      [ -n "$entry" ] || continue
      outfile="''${entry%.ts}.js"
      mkdir -p "$(dirname "$outfile")"
      echo "Compiling $entry -> $outfile"
      esbuild "$entry" \
        --bundle \
        --outfile="$outfile" \
        --platform=node \
        --format=esm \
        --target=node22 \
        '--external:@earendil-works/*' \
        '--external:@mariozechner/*' \
        '--external:@oh-my-pi/*' \
        '--external:@anthropic-ai/*' \
        '--external:@sinclair/typebox' \
        '--external:@sinclair/typebox/*' \
        '--external:typebox' \
        '--external:typebox/*' \
        '--external:diff'
      rm "$entry"
    done <<< "$entrypoints"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';
}
