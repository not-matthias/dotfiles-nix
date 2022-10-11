{pkgs, ...}: {
  # https://github.com/tars0x9752/home/blob/main/modules/neovim/default.nix
  # https://github.com/notusknot/dotfiles-nix/blob/main/modules/nvim/default.nix
  programs.neovim = {
    enable = true;
    vimAlias = true;
    extraConfig =
      builtins.readFile ./init.vim;
    plugins = with pkgs.vimPlugins; [
      #      vim-airline
      #      vim-gitgutter
      #      vim-ormolu
      vim-nix
      vim-autoformat
      #      supertab
      fzf-vim
      nerdtree

      # coc
      coc-json
      coc-yaml
      coc-html
      coc-tsserver
      coc-eslint
      coc-pairs
      coc-prettier
    ];
    coc = {
      enable = true;
      settings = {
        suggest = {
          noselect = true;
          enablePreview = true;
          enablePreselect = true;
          disableKind = true;
        };
      };
    };
  };
}
