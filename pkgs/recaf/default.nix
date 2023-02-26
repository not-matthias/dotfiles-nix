# Run with: nix-build -E '((import <nixpkgs> {}).callPackage (import ./default.nix) { })'
{
  lib,
  stdenv,
  makeWrapper,
  jre,
  makeDesktopItem,
}: let
  desktopItem = makeDesktopItem {
    name = "Recaf";
    exec = "Recaf";
    icon = "Recaf";
    desktopName = "Recaf";
    genericName = "Recaf";
    categories = ["Development"];
  };
in
  stdenv.mkDerivation rec {
    pname = "Recaf";
    version = "2.21.13";
    src = builtins.fetchurl {
      #
      url = "https://github.com/Col-E/Recaf/releases/download/${version}/recaf-${version}-J8-jar-with-dependencies.jar";
      sha256 = "03h05pp3mf61bx3vfqs4i2i3bqklidffix2kgw166wsaklgzyv4x";
    };
    dontUnpack = true;
    nativeBuildInputs = [makeWrapper];
    sourceRoot = ".";
    installPhase = ''
      install -D ${src} "$out/lib/recaf.jar"
      mkdir -p "$out/bin"
      makeWrapper "${jre}/bin/java" "$out/bin/recaf" \
          --add-flags "-jar $out/lib/recaf.jar"

      # Create Desktop Item
      mkdir -p "$out/share/applications"
      ln -s "${desktopItem}"/share/applications/* "$out/share/applications/"
    '';
    meta = with lib; {
      description = "The modern Java bytecode editor";
      homepage = "https://coley.software/Recaf/";
      sourceProvenance = with sourceTypes; [binaryBytecode];
      license = licenses.mit;
      maintainers = with maintainers; [offline];
      platforms = with platforms; unix;
    };
  }
