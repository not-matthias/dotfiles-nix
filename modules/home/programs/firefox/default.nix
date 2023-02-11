{specialArgs, ...}: {
  programs.firefox = {
    enable = true;
    profiles = {
      personal = {
        extensions = with specialArgs.addons; [
          bitwarden
          darkreader
          # auto-accepts cookies, use only with privacy-badger & ublock-origin
          i-dont-care-about-cookies
          languagetool
          link-cleaner
          privacy-badger
          ublock-origin
          unpaywall
          vimium
        ];
      };
    };
  };
}
