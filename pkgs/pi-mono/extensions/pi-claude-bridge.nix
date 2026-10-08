{
  fetchFromGitHub,
  runCommand,
  python3,
}: let
  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "b2e7255ece0b8bfd3a6429fd5c147fd59984c785";
    hash = "sha256-ri1KD0H5Nbt8lAMHbMLVf7dwaoHNbTJfhEuF4Y8lFF8=";
  };
in
  # Keep the lockfile limited to dependencies installed in the Nix build.
  runCommand "pi-claude-bridge-patched" {nativeBuildInputs = [python3];} ''
    cp -r ${src} $out
    chmod -R u+w $out
    cp ${./pi-claude-bridge-package-lock.json} $out/package-lock.json
    python3 - "$out" <<'PY'
    import json, pathlib, sys

    out = pathlib.Path(sys.argv[1])

    package = out / 'package.json'
    package_data = json.loads(package.read_text())
    package_data.pop('devDependencies', None)
    package_data.pop('peerDependencies', None)
    package.write_text(json.dumps(package_data, indent=2))

    lock = out / 'package-lock.json'
    data = json.loads(lock.read_text())
    packages = data.get('packages', {})
    root = packages.get("", {})
    root.pop('devDependencies', None)
    root.pop('peerDependencies', None)

    for name in list(packages):
        if name.startswith('node_modules/@earendil-works/'):
            del packages[name]

    zod = packages.get('node_modules/zod', {})
    if zod and not zod.get('resolved'):
        zod['resolved'] = 'https://registry.npmjs.org/zod/-/zod-' + zod['version'] + '.tgz'
        zod['integrity'] = 'sha512-rftlrkhHZOcjDwkGlnUtZZkvaPHCsDATp4pGpuOOMDaTdDDXF91wuVDJoWoPsKX/3YPQ5fHuF3STjcYyKr+Qhg=='

    lock.write_text(json.dumps(data, indent=2) + "\n")
    index = out / 'src/index.ts'
    source = index.read_text()
    compact = 'compactProviderSettings?.pathToClaudeCodeExecutable;'
    provider = 'providerSettings.pathToClaudeCodeExecutable;'
    if compact not in source or provider not in source:
        raise RuntimeError('Failed to locate Claude executable configuration')
    fallback = ' || process.env.CLAUDE_CODE_EXECUTABLE?.trim() || undefined;'
    source = source.replace(compact, compact[:-1] + fallback)
    source = source.replace(provider, provider[:-1] + fallback)
    index.write_text(source)
    PY
  ''
