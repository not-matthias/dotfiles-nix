{
  fetchFromGitHub,
  runCommand,
  python3,
}: let
  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "b113ae1b849061e63d2743931ad3363ae80b4cdf";
    hash = "sha256-9XbnueZtKnksod5brVnBMfA4jxIrlkn58r1j5uUiJec=";
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
