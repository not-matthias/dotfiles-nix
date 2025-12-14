#
{
  stdenv,
  makeWrapper,
  fetchzip,
  lib,
  patchelf,
  libxml2,
  libxcrypt,
  libuuid,
  dbus,
  fontconfig,
  freetype,
  libGL,
  libxkbcommon,
  python3,
  xorg,
  wayland,
  zlib,
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
    xorg.libX11
    xorg.libxcb
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
  ];

  libPath = lib.makeLibraryPath requiredLibs;
in
  stdenv.mkDerivation rec {
    pname = "binaryninja";
    version = "6";
    nativeBuildInputs = [makeWrapper patchelf];
    buildInputs = requiredLibs;

    src = fetchzip {
      url = "https://cdn.binary.ninja/installers/binaryninja_free_linux.zip";
      sha256 = "sha256-vdx4L/iAyO9zvwXctZ1LgDgY6rIJHkkghmGZOtfMlD0=";
    };

    dontPatchELF = true;
    allowBrokenSymlinks = true;

    installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/opt/binaryninja
            cp -r * $out/opt/binaryninja
            chmod +x $out/opt/binaryninja/binaryninja

            # Find libxml2.so files to create symlinks
            libxml2lib=$(find /nix/store -name "libxml2.so.16.1.1" -print -quit 2>/dev/null)
            if [ -f "$libxml2lib" ]; then
              ln -sf "$libxml2lib" $out/opt/binaryninja/libxml2.so.2
            fi

            # Create wrapper with LD_LIBRARY_PATH for all required libraries
            makeWrapper $out/opt/binaryninja/binaryninja \
              $out/bin/binaryninja \
              --prefix LD_LIBRARY_PATH : "$out/opt/binaryninja:${libPath}:$out/opt/binaryninja/plugins/lldb/lib"

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
      description = "Binary Ninja free edition - reverse engineering platform";
      homepage = "https://binary.ninja";
      license = licenses.unfree; # free edition but not open source
      platforms = platforms.linux;
    };
  }
