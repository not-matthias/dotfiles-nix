# Credits to: https://github.com/pupbrained/nix-config/blob/924d06b687f2d48738bde13ab6cf3ad96802dd12/pkgs/fleet.nix
{
  stdenv,
  fetchzip,
  alsa-lib,
  glib,
  zlib,
  autoPatchelfHook,
  freetype,
  fontconfig,
  mesa,
  libX11,
  libXext,
  libXrender,
  libXtst,
  libXi,
  libGL,
  makeDesktopItem,
}:
stdenv.mkDerivation rec {
  pname = "jetbrains-fleet";
  version = "1.23.175";

  # See: https://aur.archlinux.org/packages/jetbrains-fleet
  src = fetchzip {
    url = "https://download-cdn.jetbrains.com/fleet/installers/linux_x64/Fleet-${version}.tar.gz";
    sha256 = "sha256-QvyI8psjYnzQBVXZFl649y6uKuT4ilvJDuOGKa/hwRk=";
  };

  sourceRoot = ".";

  dontBuild = true;

  nativeBuildInputs = [autoPatchelfHook zlib freetype libX11 libXext libXrender libXtst libXi alsa-lib glib fontconfig mesa libGL];

  installPhase = ''
    mkdir -p $out/share/icons
    cp $src/lib/Fleet.png $out/share/icons
    cp -r $src/* $out
  '';

  desktopItem = makeDesktopItem {
    name = "jetbrains-fleet";
    exec = "Fleet";
    icon = "Fleet";
    desktopName = "JetBrains Fleet";
    genericName = "JetBrains Fleet";
    categories = ["Development"];
  };
}
