{
  fetchFromGitHub,
  runCommand,
  python3,
}: let
  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "18412173f301be96e3cd522044a709f4d41af333";
    hash = "sha256-P+4AfD033VWB/Z2Xm6OwjRagl7+HFL4e2L4iBMbLI8o=";
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
