{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation rec {
  pname = "ida-guides";
  version = "1.3.0";

  src = pkgs.fetchzip {
    url = "https://github.com/libtero/idaguides/archive/refs/heads/main.zip";
    hash = "sha256-m9KV95DAOOAk2kpwOmd3qffj71PQYrmzZfpUt1GgSK4=";
  };

  nativeBuildInputs = [pkgs.python3];

  postPatch = ''
    python3 - <<'PY'
    from pathlib import Path

    def replace(old, new):
        global text
        if old not in text:
            raise RuntimeError(f"missing patch target: {old!r}")
        text = text.replace(old, new)

    path = Path("main.py")
    text = path.read_text()
    replace(
        '        self.path = Path(__file__).parent / "ida-plugin.json"',
        '        self.path = Path(ida_diskio.get_user_idadir()) / "cfg" / "idaguides.json"',
    )
    replace(
        '        self.config = json.loads(self.path.read_text())',
        '        self.config = json.loads(self.path.read_text()) if self.path.exists() else {}',
    )
    replace(
        '        self.path.write_text(json.dumps(self.config, indent=4))',
        '        self.path.parent.mkdir(parents=True, exist_ok=True)\n        self.path.write_text(json.dumps(self.config, indent=4))',
    )
    path.write_text(text)
    PY
  '';
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/plugins
    cp main.py $out/plugins/idaguides.py

    runHook postInstall
  '';

  meta = with lib; {
    description = "Indent guides plugin for Hex-Rays decompiler";
    homepage = "https://github.com/libtero/idaguides";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
