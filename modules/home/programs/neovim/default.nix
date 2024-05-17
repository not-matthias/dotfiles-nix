# References:
# https://github.com/azuwis/nix-config/blob/885e77f74bd730f37d715c6a7ed1a9269a619f7d/common/neovim/nvchad.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    neovide

    # lsp
  ];

  # https://github.com/tars0x9752/home/blob/main/modules/neovim/default.nix
  # https://github.com/notusknot/dotfiles-nix/blob/main/modules/nvim/default.nix
  programs.neovim = {
    enable = true;
    vimAlias = true;
    extraConfig =
      builtins.readFile ./init.vim;
    plugins = with pkgs.vimPlugins; [
      #nvchad

      vim-airline
      vim-gitgutter
      vim-ormolu
      vim-nix
      vim-autoformat
      vim-nix
      vim-nixhash
      vim-yaml
      vim-toml

      fzf-vim
      nerdtree

      {
        plugin = nvim-treesitter;
        config = ''
          lua << EOF
          require('nvim-treesitter.configs').setup {
              highlight = {
                  enable = true,
                  additional_vim_regex_highlighting = false,
              },
          }
          EOF
        '';
      }
      {
        plugin = nvim-lspconfig;
        config = ''
          lua << EOF
          require('lspconfig').rust_analyzer.setup{}
          require('lspconfig').rnix.setup{}
          EOF
        '';
      }
      {
        plugin = telescope-nvim;
        config = "lua require('telescope').setup()";
      }
      {
        plugin = toggleterm-nvim;
        config = "lua require('toggleterm').setup()";
      }

      telescope-zoxide

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

  xdg.configFile."nvim/init.lua".text = ''
  '';
}
