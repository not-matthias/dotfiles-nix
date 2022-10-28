{ ...}: {
  programs.firefox = {
    enable = true;
    #    extensions = with pkgs.nurpkgs.repos.rycee.firefox-addons; [
    #      ublock-origin
    #      vimium
    #    ];
  };
}
