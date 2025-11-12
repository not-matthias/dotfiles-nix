#
{
  stdenv,
  makeWrapper,
  fetchzip,
  lib,
  patchelf,
  libxml2,
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

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/opt/binaryninja
      cp -r * $out/opt/binaryninja
      chmod +x $out/opt/binaryninja/binaryninja

      # Build RPATH including all subdirectories with libraries
      libDirs="$out/opt/binaryninja"
      libDirs="$libDirs:$out/opt/binaryninja/plugins/lldb/lib"
      libDirs="$libDirs:${libPath}"

      # Patch all ELF binaries and libraries in the opt directory
      find $out/opt/binaryninja -type f \( -executable -o -name "*.so*" \) -print0 | while IFS= read -r -d "" f; do
        patchelf --set-rpath "$libDirs" "$f" 2>/dev/null || true
      done

      makeWrapper $out/opt/binaryninja/binaryninja \
        $out/bin/binaryninja \
        --set LD_LIBRARY_PATH "$libDirs"
    '';

    dontPatchELF = true;
  }
