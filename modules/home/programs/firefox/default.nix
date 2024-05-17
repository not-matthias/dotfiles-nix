{pkgs, ...}: {
  programs.firefox = {
    package = pkgs.firefox-wayland;
    enable = true;
    # profiles = {
    #   personal = {
    #     extensions = with addons; [
    #       leechblock-ng
    #       refined-github
    #       bitwarden
    #       darkreader
    #       # auto-accepts cookies, use only with privacy-badger & ublock-origin
    #       i-dont-care-about-cookies
    #       languagetool
    #       link-cleaner
    #       privacy-badger
    #       ublock-origin
    #       unpaywall
    #       vimium
    #       libredirect
    #       clearurls
    #       sponsorblock
    #       istilldontcareaboutcookies
    #       skip-redirect
    #       smart-referer
    #       old-reddit-redirect
    #       firefox-translations
    #       aw-watcher-web
    #       duckduckgo-privacy-essentials

    #       youtube-recommended-videos # unhook.app

    #       # TODO:
    #       # modern-for-wikipedia
    #       # chameleon
    #       # fakespot
    #     ];
    #   };
    #   university = {
    #   };
    # };
  };
}
