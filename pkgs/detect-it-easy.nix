# Build with: nix-build -E '((import <nixpkgs> {}).callPackage (import ./default.nix) { })'
# References:
# - https://github.com/NixOS/nixpkgs/blob/7e325cb89453651dbe9a17b67a4f85c4f71d4c08/pkgs/tools/misc/via/default.nix#L2
# - https://nixos.wiki/wiki/Appimage
{
  lib,
  appimageTools,
  ...
}: let
  pname = "die";
  version = "3.07";
  name = "${pname}-${version}";
  src = builtins.fetchurl {
    url = "https://github.com/horsicq/DIE-engine/releases/download/${version}/Detect_It_Easy-${version}-x86_64.AppImage";
    name = "detect-it-easy-${version}.AppImage";
    sha256 = "9rr9oq2YQngN6EshFRu71/Qlle9fyjDL2yUWYrg1NwI=";
  };
  appimageContents = appimageTools.extractType2 {inherit name src;};
in
  appimageTools.wrapType2 {
    inherit name src;

    extraInstallCommands = ''
      mv $out/bin/${name} $out/bin/${pname}
      install -m 444 -D ${appimageContents}/die.desktop -t $out/share/applications
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = with lib; {
      description = "Program for determining types of files for Windows, Linux and MacOS.";
      homepage = "https://github.com/horsicq/Detect-It-Easy";
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      license = licenses.mit;
      maintainers = with maintainers; [offline];
      platforms = with platforms; unix;
    };
  }
