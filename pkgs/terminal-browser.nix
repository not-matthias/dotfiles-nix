{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  patchelf,
  # Runtime deps of the bundled prebuilt Electron runtime (not itself a
  # Nix package).
  glib,
  nspr,
  nss,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cups,
  dbus,
  cairo,
  gtk3,
  pango,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libgbm,
  expat,
  libxcb,
  libxkbcommon,
  alsa-lib,
  systemd,
}: let
  libPaths = map (p: "${lib.getLib p}/lib") [
    stdenv.cc.cc
    glib
    nspr
    nss
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    cairo
    gtk3
    pango
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libgbm
    expat
    libxcb
    libxkbcommon
    alsa-lib
    systemd
  ];
  # $ORIGIN first so electron still finds its own bundled libs (libffmpeg,
  # libEGL, ...); store paths cover the rest of the dependency graph.
  rpath = "$ORIGIN:${lib.concatStringsSep ":" libPaths}";
in
  stdenv.mkDerivation rec {
    pname = "terminal-browser";
    version = "0.6.0";

    src = fetchurl {
      url = "https://github.com/zenbu-labs/terminal-browser/releases/download/v${version}/${pname}-linux-x64.tar.gz";
      hash = "sha256-fCN1WTYjoSEJYV7KlM6u7OamGTxMyVW6FZIV8PbAn/c=";
    };

    nativeBuildInputs = [makeWrapper patchelf];

    dontBuild = true;

    # stdenv's patchELF hook would shrink our rpath and downgrade RPATH to
    # RUNPATH; the prebuilt binaries are already stripped.
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      dist=$out/lib/${pname}
      mkdir -p $dist
      cp -r . $dist

      # The stock launcher resolves its install root from $0, which breaks
      # under profile symlinks; run the CLI directly instead.
      makeWrapper $dist/electron/electron $out/bin/${pname} \
        --add-flags "$dist/cli/dist/main.js" \
        --set TERMINAL_BROWSER_DIST_ROOT "$dist" \
        --set ELECTRON_RUN_AS_NODE 1

      # The electron binary, the crashpad handler and the pixel.node addon
      # are linked against libraries that only exist in the nix store; bake
      # the store paths into their rpath, preserving $ORIGIN.
      # --force-rpath is required: the original binary uses DT_RPATH, which
      # is the global scope the dlopened bundled libs (libEGL, libGLESv2, ...)
      # rely on to resolve their own transitive deps.
      patchelf --force-rpath --set-rpath '${rpath}' \
        $dist/electron/electron \
        $dist/electron/chrome_crashpad_handler \
        $dist/browser/native/pixel.node

      runHook postInstall
    '';

    meta = {
      description = "A browser that runs directly inside your existing terminal via the kitty graphics protocol";
      homepage = "https://github.com/zenbu-labs/terminal-browser";
      downloadPage = "https://github.com/zenbu-labs/terminal-browser/releases";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  }
