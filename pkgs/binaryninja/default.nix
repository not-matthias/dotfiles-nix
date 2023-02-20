# References:
# - https://cs.github.com/novafacing/nixosrc/blob/26f2cb87cac2bbc6e4bf7754422cee4f7f9461ef/modules/home/binaryninja.nix?q=binaryninja+language%3Anix
# - https://cs.github.com/buckley310/nixos-config/blob/e54656beb26b43acc65423271ddc6ab145d27db9/pkgs/binaryninja/default.nix
# - https://cs.github.com/multun/nix/blob/b382d36a93719235b9355db122227d3e7712d875/binaryninja.nix?q=binaryninja+language%3Anix
{
  stdenv,
  glib,
  libglvnd,
  xorg,
  fontconfig,
  dbus,
  fetchzip,
  makeWrapper,
  autoPatchelfHook,
  libGL,
  qt6,
}:
stdenv.mkDerivation {
  name = "binary-ninja";

  src = fetchzip {
    url = "https://cdn.binary.ninja/installers/BinaryNinja-demo.zip";
    sha256 = "SGMVj+LR1bsSK+0Yeh1JXEokTHQl580n1M0IuMmE2xk=";
  };

  installPhase = ''
    mkdir -p $out/share/binary-ninja
    cp -r * $out/share/binary-ninja
  '';

  nativeBuildInputs = [
    autoPatchelfHook # <-- this fails
    makeWrapper
    qt6.wrapQtAppsHook
  ];
  buildInputs = [
    makeWrapper
    stdenv.cc.cc
    glib
    fontconfig
    dbus
    libglvnd
    xorg.libX11
    xorg.libXi
    xorg.libXrender
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXcursor
    xorg.libXtst
    xorg.libXrandr
    xorg.libxcb
    xorg.xcbutilwm
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    libGL

    qt6.qtbase
  ];
}
