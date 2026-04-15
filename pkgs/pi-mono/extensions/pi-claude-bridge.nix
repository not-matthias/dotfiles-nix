{
  fetchFromGitHub,
  runCommand,
  python3,
}: let
  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "05424952c9b2afeb1bcd07ce5414fa1d996568a2";
    hash = "sha256-q5i47U79Ia2z5V6ihpWXlgYLtpCv+lY5OuntaNZ+GoE=";
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
