{
  config,
  lib,
  unstable,
  ...
}: let
  cfg = config.programs.tradingview;
  package = unstable.tradingview;
  desktopFile = "tradingview.desktop";
  loginMime = "x-scheme-handler/tradingview";
in {
  options.programs.tradingview.enable = lib.mkEnableOption "TradingView Desktop with browser login";

  config = lib.mkIf cfg.enable {
    home.packages = [package];

    xdg.desktopEntries.tradingview = {
      name = "TradingView";
      comment = "Charting platform for traders and investors";
      exec = "${lib.getExe package} %U";
      icon = "tradingview";
      terminal = false;
      categories = ["Office" "Finance"];
      mimeType = [loginMime];
      settings.StartupWMClass = "TradingView";
    };

    xdg.mimeApps = {
      enable = true;
      associations.added.${loginMime} = [desktopFile];
      defaultApplications.${loginMime} = [desktopFile];
    };
  };
}
