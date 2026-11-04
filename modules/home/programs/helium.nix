{
  config,
  flakes,
  lib,
  ...
}: {
  imports = [flakes.helium.homeModules.default];
  home.sessionVariables.BROWSER = lib.mkIf config.programs.helium.enable (lib.mkDefault "helium");

  programs.helium = {
    commandLineArgs = [
      "--no-default-browser-check"
      "--disable-breakpad"
      "--enable-features=AcceleratedVideoEncoder,ParallelDownloading,PlatformHEVCDecoderSupport"
    ];

    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "hlepfoohegkhhmjieoechaddaejaokhf" # Refined GitHub
      "blaaajhemilngeeffpbfkdjjoefldkok" # LeechBlock NG
      "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube
      "khncfooichmfjbepaaaebmommgaepoid" # Unhook - Remove YouTube Recommended & Shorts
      "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "hkgfoiooedgoejojocmhlaklaeopbecg" # Picture-in-Picture Extension (by Google)
      "dneaehbmnbhcippjikoajpoabadpodje" # Old Reddit Redirect
      "hhinaapppaileiechjoiifaancjggfjm" # Web Scrobbler
      "nglaklhklhcoonedhgnpgddginnjdadi" # ActivityWatch Web Watcher
      "kkmlkkjojmombglmlpbpapmhcaljjkde" # Zhongwen: Chinese-English Dictionary
    ];
  };
}
