# Build with: nix-build -E '((import <nixpkgs> {}).callPackage (import ./default.nix) { })'
{
  lib,
  appimageTools,
  ...
}: let
  pname = "WeekToDo";
  version = "2.0.0";
  name = "${pname}-${version}";
  src = builtins.fetchurl {
    url = "https://github.com/manuelernestog/WeekToDo/releases/download/v${version}/WeekToDo-${version}.AppImage";
    name = "WeekToDo-${version}.AppImage";
    sha256 = "02sb2d6d7bry3alv5yhzy6dnnl0xdax7dk8rj5i1h368dnmmzgdx";
  };
  appimageContents = appimageTools.extractType2 {inherit name src;};
in
  appimageTools.wrapType2 {
    inherit name src;

    extraInstallCommands = ''
      mv $out/bin/${name} $out/bin/${pname}
      install -m 444 -D ${appimageContents}/weektodo.desktop -t $out/share/applications
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = with lib; {
      description = "TODO";
      homepage = "https://github.com/manuelernestog/WeekToDo";
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      license = licenses.gpl3;
      maintainers = with maintainers; [offline];
      platforms = with platforms; unix;
    };
  }
