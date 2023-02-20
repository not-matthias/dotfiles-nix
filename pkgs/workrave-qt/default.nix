# References:
# - https://cs.github.com/flyingcircusio/nixpkgs/blob/51f03c41bdf023e305f7a48205b191cceb67ead7/pkgs/applications/office/kitsas/default.nix?q=qmake+language%3Anix
{
  stdenv,
  fetchFromGitHub,
  lib,
  qmake,
  qtbase,
  qtsvg,
  qtwebengine,
  qttools,
  autoPatchelfHook,
  wrapQtAppsHook,
  makeDesktopItem,
  freetype,
  libX11,
  libXext,
  libXrender,
  libXtst,
  libXi,
  libGL,
  glib,
  fontconfig,
  mesa,
}:
stdenv.mkDerivation rec {
  pname = "WorkraveQt";
  version = "0.3";

  src = fetchFromGitHub {
    owner = "mrexodia";
    repo = "${pname}";
    rev = "v${version}";
    sha256 = "sha256-Yf5CgdQTla5THp9CpZW8Nq2iufbraOT1fcIdtKi1Mxk=";
  };

  nativeBuildInputs = [autoPatchelfHook qmake wrapQtAppsHook freetype libX11 libXext libXrender libXtst libXi glib fontconfig mesa libGL];
  buildInputs = [qtbase qttools qtsvg qtwebengine];

  qmakeFlags = ["src/WorkraveQt.pro"];

  desktopItem = makeDesktopItem {
    name = "WorkraveQt";
    exec = "WorkraveQt";
    icon = "sheep";
    desktopName = "WorkraveQt";
    genericName = "WorkraveQt";
    categories = ["Utility"];
  };

  installPhase = ''
    install -Dm755 WorkraveQt -t $out/bin
    install -Dm644 ${src}/src/images/sheep.svg -t $out/share/icons/hicolor/scalable/apps

    # Create Desktop Item
    mkdir -p "$out/share/applications"
    ln -s "${desktopItem}"/share/applications/* "$out/share/applications/"
  '';

  meta = with lib; {
    description = " Modern reimplementation of Workrave in Qt. Optimized to look out for you where you don't.";
    homepage = "https://github.com/mrexodia/WorkraveQt";
    license = licenses.mit;
  };
}
