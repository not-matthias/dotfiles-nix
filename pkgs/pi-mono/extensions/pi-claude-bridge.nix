{
  fetchFromGitHub,
  runCommand,
  python3,
}: let
  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "5a671a28bda55f4ede87b105236ba239f9354fde";
    hash = "sha256-BKrXEaB4fpd3q3rDyWDTUst9wJqYXO/5NZ2g+Ox1Yus=";
  };
in
  # Patch package-lock.json to add missing resolved/integrity for zod v4
  # (zod v4 uses a lockfile entry without resolved URL, which breaks prefetch-npm-deps)
  runCommand "pi-claude-bridge-patched" {nativeBuildInputs = [python3];} ''
    cp -r ${src} $out
    chmod -R u+w $out
    python3 -c "
    import json, pathlib
    lock = pathlib.Path('$out/package-lock.json')
    data = json.loads(lock.read_text())
    zod = data.get('packages', {}).get('node_modules/zod', {})
    if zod and not zod.get('resolved'):
        zod['resolved'] = 'https://registry.npmjs.org/zod/-/zod-' + zod['version'] + '.tgz'
        zod['integrity'] = 'sha512-rftlrkhHZOcjDwkGlnUtZZkvaPHCsDATp4pGpuOOMDaTdDDXF91wuVDJoWoPsKX/3YPQ5fHuF3STjcYyKr+Qhg=='
        lock.write_text(json.dumps(data, indent=2))
    "
  ''
