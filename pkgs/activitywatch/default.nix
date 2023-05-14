{
  lib,
  appimageTools,
  ...
}: let
  pname = "activitywatch";
  version = "0.12.3b1";
  name = "${pname}-${version}";
  src = builtins.fetchurl {
    url = "https://github.com/ActivityWatch/activitywatch/releases/download/v${version}/activitywatch-linux-x86_64.AppImage";
    name = "activitywatch-linux-x86_64.AppImage";
    sha256 = "sha256:1wwwrky7ns3l7bwmjzb6722h7168gf7xkgfpbwq0zdgiq16znpdk";
  };
  appimageContents = appimageTools.extractType2 {inherit name src;};
in
  appimageTools.wrapType2 {
    inherit name src;

    extraInstallCommands = ''
      mv $out/bin/${name} $out/bin/${pname}

      mkdir -p $out/share/{applications,icons}
      ln -s ${appimageContents}/activitywatch.png $out/share/icons
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = with lib; {
      description = "The best free and open-source automated time tracker. Cross-platform, extensible, privacy-focused.";
      homepage = "https://github.com/ActivityWatch/activitywatch";
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      license = licenses.gpl3;
      maintainers = with maintainers; [offline];
      platforms = with platforms; unix;
    };
  }
