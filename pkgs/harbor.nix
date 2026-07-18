{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  git,
  curl,
  jq,
  deno,
}:
# Harbor CLI. The entry users run is `harbor.sh` — a ~12.5k-line bash script
# that orchestrates `docker compose` for a local LLM stack (Ollama,
# llama.cpp, Open WebUI, ...). The `harbor` python entry in pyproject.toml
# is a 21-line shim that just execs this bash script, so packaging the
# python package would only install a launcher with no source tree.
#
# harbor.sh self-locates its source root via BASH_SOURCE and needs
# compose.yml, services/, .scripts/, profiles/ as siblings; it also writes
# .env, profiles/, and services/*/override.env into that root. The Nix
# store is read-only, so the wrapper seeds a writable ~/.harbor from the
# store on first run and on every version bump, then execs the seeded
# harbor.sh. harbor's .gitignore keeps user state (.env, profiles/*.env,
# services/*/override.env) out of the store tree, so a plain cp preserves
# it across re-seeds. `harbor upgrade` (git checkout) is inert under Nix —
# bump this package to update.
stdenv.mkDerivation rec {
  pname = "harbor";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "av";
    repo = "harbor";
    rev = "v${version}";
    hash = "sha256-xcVcIjnqbL7LC55lDSUurTGQ3xFA7cir1IJLAA8uFHE=";
  };

  dontBuild = true;
  nativeBuildInputs = [makeWrapper];

  # Service scripts under services/*/ run INSIDE docker containers, so their
  # shebangs (#!/bin/sh, #!/usr/bin/env bash) must stay as-is — patchShebangs
  # would rewrite them to /nix/store/.../bash, which doesn't exist inside the
  # container images. It also mangles `#!/usr/bin/env -S deno run -A` shebangs
  # on the .ts routines. harbor.sh itself is invoked via `exec bash` from the
  # wrapper, so its shebang is never consulted on the host.
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/harbor $out/bin
    cp -r . $out/share/harbor/
    chmod -R u+w $out/share/harbor

    cat > $out/bin/harbor <<'WRAPPER'
    #!/usr/bin/env bash
    set -e
    HARBOR_HOME="''${HARBOR_HOME:-$HOME/.harbor}"
    NIX_VERSION="@version@"
    if [ ! -f "$HARBOR_HOME/harbor.sh" ] || [ "$(cat "$HARBOR_HOME/.nix-version" 2>/dev/null)" != "$NIX_VERSION" ]; then
      mkdir -p "$HARBOR_HOME"
      # services/*/override.env are tracked defaults that users customize
      # via `harbor env`; back them up before re-seeding and restore them
      # over the new defaults so a version bump doesn't clobber user config.
      # .env and profiles/*.env are gitignored (absent from the store tree)
      # so the cp below already leaves them untouched.
      _bak="$(mktemp -d)"
      if [ -d "$HARBOR_HOME/services" ]; then
        for f in "$HARBOR_HOME"/services/*/override.env; do
          [ -f "$f" ] || continue
          _svc="$(basename "$(dirname "$f")")"
          mkdir -p "$_bak/services/$_svc"
          cp -a "$f" "$_bak/services/$_svc/override.env"
        done
      fi
      cp -r "@out@/share/harbor/." "$HARBOR_HOME/"
      if [ -d "$_bak/services" ]; then
        cp -rf "$_bak/services/." "$HARBOR_HOME/services/"
      fi
      rm -rf "$_bak"
      chmod -R u+w "$HARBOR_HOME"
      echo "$NIX_VERSION" > "$HARBOR_HOME/.nix-version"
    fi
    exec bash "$HARBOR_HOME/harbor.sh" "$@"
    WRAPPER
    chmod +x $out/bin/harbor
    substituteInPlace $out/bin/harbor --subst-var out --subst-var version
    runHook postInstall
  '';

  # docker is a system service (virtualisation.docker.enable) and stays on
  # the user's PATH. deno is required for harbor's routine system
  # (mergeComposeFiles, configSearch, ...) which `harbor up` invokes; git,
  # curl, jq are lightweight tools harbor.sh shells out to directly.
  postFixup = ''
    wrapProgram $out/bin/harbor --prefix PATH : ${lib.makeBinPath [git curl jq deno]}
  '';

  meta = {
    description = "CLI for running a containerized local LLM stack (Ollama, llama.cpp, Open WebUI, ...) with one command";
    homepage = "https://github.com/av/harbor";
    downloadPage = "https://github.com/av/harbor/releases";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "harbor";
  };
}
