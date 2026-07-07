{pkgs, ...}: {
  programs.chromium = {
    package = pkgs.chromium;

    commandLineArgs = [
      "--no-default-browser-check"
      "--disable-breakpad"
    ];
  };
}
