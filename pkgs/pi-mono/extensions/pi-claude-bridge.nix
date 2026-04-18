{
  fetchFromGitHub,
  runCommand,
  python3,
}: let
  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "2e27d9648c5822c790f48158d28695912cce7930";
    hash = "sha256-6He/Le6PtjKQr+OLAHlDcH25VxgnCNWOJbVAd6YZbYI=";
  };
in
  # Patch package-lock.json to add missing resolved/integrity for zod v4
  # (zod v4 uses a lockfile entry without resolved URL, which breaks prefetch-npm-deps)
  runCommand "pi-claude-bridge-patched" {nativeBuildInputs = [python3];} ''
    cp -r ${src} $out
    chmod -R u+w $out
    python3 - "$out" <<'PY'
    import json, pathlib, sys

    out = pathlib.Path(sys.argv[1])

    lock = out / 'package-lock.json'
    data = json.loads(lock.read_text())
    zod = data.get('packages', {}).get('node_modules/zod', {})
    if zod and not zod.get('resolved'):
        zod['resolved'] = 'https://registry.npmjs.org/zod/-/zod-' + zod['version'] + '.tgz'
        zod['integrity'] = 'sha512-rftlrkhHZOcjDwkGlnUtZZkvaPHCsDATp4pGpuOOMDaTdDDXF91wuVDJoWoPsKX/3YPQ5fHuF3STjcYyKr+Qhg=='
        lock.write_text(json.dumps(data, indent=2))

    index = out / 'index.ts'
    source = index.read_text()
    source = source.replace(
        'const DIAG_LOG_PATH = join(homedir(), ".pi", "agent", "claude-bridge-diag.log");\n',
        'const DIAG_LOG_PATH = join(homedir(), ".pi", "agent", "claude-bridge-diag.log");\nconst CLAUDE_CODE_EXECUTABLE = process.env.CLAUDE_CODE_EXECUTABLE?.trim() || undefined;\n',
    )
    source = source.replace(
        '\t\textraArgs,\n',
        '\t\textraArgs,\n\t\t...(CLAUDE_CODE_EXECUTABLE ? { pathToClaudeCodeExecutable: CLAUDE_CODE_EXECUTABLE } : {}),\n',
        1,
    )
    source = source.replace(
        '\t\t\t...(effort ? { effort } : {}),\n',
        '\t\t\t...(effort ? { effort } : {}),\n\t\t\t...(CLAUDE_CODE_EXECUTABLE ? { pathToClaudeCodeExecutable: CLAUDE_CODE_EXECUTABLE } : {}),\n',
        1,
    )
    index.write_text(source)
    PY
  ''
