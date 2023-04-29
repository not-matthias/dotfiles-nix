#
{
  stdenv,
  buildFHSUserEnv,
  makeWrapper,
  fetchzip,
}: let
  binaryninja = stdenv.mkDerivation rec {
    name = "binaryninja";
    nativeBuildInputs = [makeWrapper];

    src = fetchzip {
      url = "https://cdn.binary.ninja/installers/BinaryNinja-demo.zip";
      sha256 = "SGMVj+LR1bsSK+0Yeh1JXEokTHQl580n1M0IuMmE2xk=";
    };

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/opt/binaryninja
      cp -r * $out/opt/binaryninja
      chmod +x $out/opt/binaryninja/binaryninja
      makeWrapper $out/opt/binaryninja/binaryninja \
        $out/bin/binaryninja
    '';

    dontPatchELF = true;
  };
in
  buildFHSUserEnv {
    name = binaryninja.name;

    targetPkgs = pkgs:
      with pkgs; [
        dbus
        fontconfig
        freetype
        libGL
        libxkbcommon
        python3
        xorg.libX11
        xorg.libxcb
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilwm
        wayland
        zlib
        binaryninja
      ];

    runScript = "binaryninja";
  }
