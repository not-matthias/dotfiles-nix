{flakes, ...}: {
  imports = [flakes.helium.homeModules.default];

  programs.helium = {
    commandLineArgs = [
      "--no-default-browser-check"
      "--disable-breakpad"
      "--restore-last-session"
    ];

    extensions = [
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "hlepfoohegkhhmjieoechaddaejaokhf" # Refined GitHub
      "blaaajhemilngeeffpbfkdjjoefldkok" # LeechBlock NG
      "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube
      "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "dneaehbmnbhcippjikoajpoabadpodje" # Old Reddit Redirect
      "hhinaapppaileiechjoiifaancjggfjm" # Web Scrobbler
      "nglaklhklhcoonedhgnpgddginnjdadi" # ActivityWatch Web Watcher
    ];
  };
}
