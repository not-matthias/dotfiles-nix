#
{
  stdenv,
  requireFile,
  lib,
  patchelf,
  unzip,
  libxml2,
  libxcrypt,
  libuuid,
  dbus,
  fontconfig,
  freetype,
  libGL,
  libxkbcommon,
  python3,
  libx11,
  libxcb,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-wm,
  wayland,
  zlib,
  # Qt5 WebEngine deps (bundled by the personal edition)
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  alsa-lib,
  expat,
  glib,
  libkrb5,
  nspr,
  nss,
  sqlite,
  gcc-unwrapped,
}: let
  requiredLibs = [
    libxml2
    dbus
    fontconfig
    freetype
    libGL
    libxkbcommon
    libxcrypt
    libuuid
    python3
    wayland
    zlib
    libx11
    libxcb
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-wm
    # Qt5 WebEngine deps
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    alsa-lib
    expat
    glib
    libkrb5
    nspr
    nss
    gcc-unwrapped.lib
    sqlite
  ];

  libPath = lib.makeLibraryPath requiredLibs;
in
  stdenv.mkDerivation rec {
    pname = "binaryninja";
    version = "dev-personal";
    nativeBuildInputs = [patchelf unzip];
    buildInputs = requiredLibs;

    # Free version:
    # src = fetchzip {
    #   url = "https://cdn.binary.ninja/installers/binaryninja_free_linux.zip";
    #   sha256 = "sha256-vdx4L/iAyO9zvwXctZ1LgDgY6rIJHkkghmGZOtfMlD0=";
    # };
    src = requireFile {
      name = "binaryninja_linux_dev_personal.zip";
      url = "https://binary.ninja/";
      sha256 = "sha256-xvoaYRUpkAWvUPsoRjwkTGjspLtf/NPk4A4JYpjAGIA=";
    };

    dontPatchELF = true;
    allowBrokenSymlinks = true;

    unpackPhase = ''
      unzip -q "$src"
      cd binaryninja
    '';

    installPhase = ''
        mkdir -p $out/bin $out/opt/binaryninja
        cp -r * $out/opt/binaryninja
        chmod +x $out/opt/binaryninja/binaryninja
        ln -sf ${lib.getLib libxml2}/lib/libxml2.so $out/opt/binaryninja/libxml2.so.2
        # The upstream application updates files beside its executable. Keep the
        # Nix store copy as the seed and run a writable per-build copy instead.
        cat > $out/bin/binaryninja <<EOF
      #!${stdenv.shell}
      set -eu

      source_dir="$out/opt/binaryninja"
      source_root="$out"
      cache_root="\''${XDG_CACHE_HOME:-\''${HOME}/.cache}/binaryninja"
      runtime_name="\$(basename "\''${source_root}")"
      runtime_dir="\''${cache_root}/\''${runtime_name}"

      if [ ! -x "\''${cache_root}/\''${runtime_name}/binaryninja" ]; then
        mkdir -p "\''${XDG_CACHE_HOME:-\''${HOME}/.cache}/binaryninja"
        tmp_dir=\$(mktemp -d "\''${cache_root}/.binaryninja.XXXXXX")
        trap 'rm -rf "\''${tmp_dir}"' EXIT HUP INT TERM
        cp -a "\''${source_dir}/." "\''${tmp_dir}/"
        chmod -R u+rwX "\''${tmp_dir}"
        if [ ! -e "\''${cache_root}/\''${runtime_name}" ]; then
          mv "\''${tmp_dir}" "\''${cache_root}/\''${runtime_name}"
        fi
      fi
      ln -sfn ${lib.getLib libxml2}/lib/libxml2.so "\''${cache_root}/\''${runtime_name}/libxml2.so.2"
      export LD_LIBRARY_PATH="\''${cache_root}/\''${runtime_name}:${libPath}:\''${cache_root}/\''${runtime_name}/plugins/lldb/lib\''${LD_LIBRARY_PATH:+:\''${LD_LIBRARY_PATH}}"
      unset QT_STYLE_OVERRIDE QT_QPA_PLATFORMTHEME QT_PLUGIN_PATH
      export QT_QPA_PLATFORM="wayland;xcb"
      exec "\''${cache_root}/\''${runtime_name}/binaryninja" "\''${@}"
      EOF
        chmod +x $out/bin/binaryninja

              # Desktop entry + icon
              mkdir -p $out/share/applications
              iconPath=$(find $out/opt/binaryninja -maxdepth 3 -type f -iname "binaryninja*.png" | head -n1)
              if [ -n "$iconPath" ]; then
                # Install icon into hicolor if size can be derived
                sizeDir="$(basename $(dirname "$iconPath"))"
                mkdir -p $out/share/icons/hicolor/$sizeDir/apps || true
                cp "$iconPath" $out/share/icons/hicolor/$sizeDir/apps/binaryninja.png || true
                iconLine="Icon=binaryninja"
              else
                iconLine="Icon=binaryninja"
              fi
              cat > $out/share/applications/binaryninja.desktop <<EOF
        [Desktop Entry]
        Type=Application
        Name=Binary Ninja
        GenericName=Reverse Engineering Platform
        Comment=Interactive disassembler and decompiler
        Exec=$out/bin/binaryninja %f
        $iconLine
        Terminal=false
        Categories=Development;Debugger;
        StartupWMClass=Binary Ninja
        EOF
    '';

    postFixupPhases = ["finalPatchPhase"];
    finalPatchPhase = ''
      # Patch all ELF binaries and libraries with RPATH
      find $out/opt/binaryninja -type f \( -executable -o -name "*.so*" \) -print0 | while IFS= read -r -d "" f; do
        if file "$f" | grep -q "ELF"; then
          patchelf --set-rpath "${libPath}:$out/opt/binaryninja:$out/opt/binaryninja/plugins/lldb/lib" "$f" 2>/dev/null || true
        fi
      done
    '';

    meta = with lib; {
      description = "Binary Ninja personal edition - reverse engineering platform";
      homepage = "https://binary.ninja";
      license = licenses.unfree;
      platforms = platforms.linux;
    };
  }
