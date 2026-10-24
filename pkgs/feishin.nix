# https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/fe/feishin/package.nix
# https://github.com/hlissner/dotfiles/blob/85707eb6448774c8cd3df0ea167ed46a982f7d96/packages/feishin/default.nix
{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  electron_43,
  pnpmConfigHook,
  pnpm,
  fetchPnpmDeps,
  darwin,
  copyDesktopItems,
  makeDesktopItem,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  glib,
  gtk3,
  libGL,
  libdrm,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxcb,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
}: let
  pname = "feishin";
  version = "1.17.0";

  src = fetchFromGitHub {
    owner = "jeffvli";
    repo = "feishin";
    tag = "v${version}";
    hash = "sha256-1ZIw5XiN+2EhpHmdvN0HxgMSvn4QvN9B+ZJ3RlPXhLw=";
  };

  electron = electron_43;
  sourcePackage = buildNpmPackage {
    inherit pname version;

    inherit src;

    npmConfigHook = pnpmConfigHook;

    npmDeps = null;
    pnpmDeps = fetchPnpmDeps {
      inherit
        pname
        version
        src
        ;
      fetcherVersion = 3;
      hash = "sha256-AaZTCuqG4kIiz1pHFaXMAoTj4NDX7gAZY0RfStLT5QY=";
    };

    env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

    nativeBuildInputs =
      [pnpm]
      ++ lib.optionals (stdenv.hostPlatform.isLinux) [copyDesktopItems]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [darwin.autoSignDarwinBinariesHook];

    postPatch = ''
      # release/app dependencies are installed on preConfigure
      substituteInPlace package.json \
        --replace-fail '"postinstall": "install-electron && electron-builder install-app-deps",' ""

      # Don't check for updates.
      substituteInPlace src/main/index.ts \
        --replace-fail "autoUpdater.checkForUpdatesAndNotify();" ""
    '';

    postBuild =
      lib.optionalString stdenv.hostPlatform.isDarwin ''
        # electron-builder appears to build directly on top of Electron.app, by overwriting the files in the bundle.
        cp -r ${electron.dist}/Electron.app ./
        find ./Electron.app -name 'Info.plist' | xargs -d '\n' chmod +rw

        # Disable code signing during build on macOS.
        # https://github.com/electron-userland/electron-builder/blob/fa6fc16/docs/code-signing.md#how-to-disable-code-signing-during-the-build-process-on-macos
        export CSC_IDENTITY_AUTO_DISCOVERY=false
        sed -i "/afterSign/d" package.json
      ''
      + ''
        npm exec electron-builder -- \
          --dir \
          -c.electronDist=${
          if stdenv.hostPlatform.isDarwin
          then "./"
          else electron.dist
        } \
          -c.electronVersion=${electron.version} \
          -c.npmRebuild=false
      '';

    installPhase =
      ''
        runHook preInstall
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        mkdir -p $out/{Applications,bin}
        cp -r release/build/**/Feishin.app $out/Applications/
        makeWrapper $out/Applications/Feishin.app/Contents/MacOS/Feishin $out/bin/feishin
      ''
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p $out/share/feishin

        pushd dist/*-unpacked/
        cp -r locales resources{,.pak} $out/share/feishin
        popd

        # Code relies on checking app.isPackaged, which returns false if the executable is electron.
        # Set ELECTRON_FORCE_IS_PACKAGED=1.
        # https://github.com/electron/electron/issues/35153#issuecomment-1202718531
        makeWrapper ${lib.getExe electron} $out/bin/feishin \
          --add-flags $out/share/feishin/resources/app.asar \
          --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
          --set ELECTRON_FORCE_IS_PACKAGED=1 \
          --inherit-argv0

        for size in 32 64 128 256 512 1024; do
          mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
          ln -s \
            $out/share/feishin/resources/assets/icons/"$size"x"$size".png \
            $out/share/icons/hicolor/"$size"x"$size"/apps/feishin.png
        done
      ''
      + ''
        runHook postInstall
      '';

    inherit desktopItems;

    meta = {
      description = "Full-featured Subsonic/Jellyfin compatible desktop music player";
      homepage = "https://github.com/jeffvli/feishin";
      changelog = "https://github.com/jeffvli/feishin/releases/tag/v${version}";
      sourceProvenance = with lib.sourceTypes; [fromSource];
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.unix;
      mainProgram = "feishin";
      maintainers = with lib.maintainers; [
        onny
        jlbribeiro
      ];
    };
  };
  desktopItems = [
    (makeDesktopItem {
      name = "feishin";
      desktopName = "Feishin";
      comment = "Full-featured Subsonic/Jellyfin compatible desktop music player";
      icon = "feishin";
      exec = "feishin %u";
      categories = [
        "Audio"
        "AudioVideo"
      ];
      mimeTypes = ["x-scheme-handler/feishin"];
    })
  ];
  runtimeLibs = [
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    glib
    gtk3
    libGL
    libdrm
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxcb
    libxkbcommon
    libxrandr
    mesa
    nspr
    nss
    pango
    systemd
  ];

  # The ARM64 artifact ships x86-64 abstract-socket bindings.node, so retain the source fallback.
  binaryPackage = stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/jeffvli/feishin/releases/download/v${version}/Feishin-linux-x64.tar.xz";
      hash = "sha256-dfX5vRPpxxd4dQdUQLFuthdpJdqzvw0VUiDrROT37oI=";
    };
    sourceRoot = "Feishin-linux-x64";

    dontBuild = true;
    dontConfigure = true;
    dontStrip = true;

    nativeBuildInputs = [
      autoPatchelfHook
      copyDesktopItems
      makeWrapper
    ];
    buildInputs = runtimeLibs;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/feishin" "$out/bin"
      cp -a ./. "$out/share/feishin/"

      makeWrapper "$out/share/feishin/feishin" "$out/bin/feishin" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        --prefix LD_LIBRARY_PATH : "$out/share/feishin:${lib.makeLibraryPath runtimeLibs}" \
        --set ELECTRON_FORCE_IS_PACKAGED 1 \
        --set DISABLE_AUTO_UPDATES 1

      for size in 32 64 128 256 512 1024; do
        mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
        ln -s "$out/share/feishin/resources/assets/icons/''${size}x''${size}.png" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/feishin.png"
      done
      runHook postInstall
    '';

    inherit desktopItems;

    meta = {
      description = "Full-featured Subsonic/Jellyfin compatible desktop music player";
      homepage = "https://github.com/jeffvli/feishin";
      changelog = "https://github.com/jeffvli/feishin/releases/tag/v${version}";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      license = lib.licenses.gpl3Plus;
      platforms = ["x86_64-linux"];
      mainProgram = "feishin";
      maintainers = with lib.maintainers; [
        onny
        jlbribeiro
      ];
    };
  };
in
  if stdenv.hostPlatform.system == "x86_64-linux"
  then binaryPackage
  else sourcePackage
