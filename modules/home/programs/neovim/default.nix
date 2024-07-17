# References:
# https://github.com/azuwis/nix-config/blob/885e77f74bd730f37d715c6a7ed1a9269a619f7d/common/neovim/nvchad.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    neovide

    # lsp
  ];

  # https://github.com/tars0x9752/home/blob/main/modules/neovim/default.nix
  # https://github.com/notusknot/dotfiles-nix/blob/main/modules/nvim/default.nix
  # programs.neovim = {
  #   enable = false;
  #   vimAlias = true;
  #   extraConfig =
  #     builtins.readFile ./init.vim;
  #   plugins = with pkgs.vimPlugins; [
  #     nvchad

  #     vim-commentar
  #     vim-ormolu
  #     vim-nix
  #     vim-autoformat
  #     vim-nix
  #     vim-nixhash
  #     vim-yaml
  #     vim-toml

  #     fzf-vim

  #     {
  #       plugin = nvim-lspconfig;
  #       config = ''
  #         lua << EOF
  #         require('lspconfig').rust_analyzer.setup{}
  #         require('lspconfig').rnix.setup{}
  #         EOF
  #       '';
  #     }

  #     # coc
  #     coc-json
  #     coc-yaml
  #     coc-html
  #     coc-tsserver
  #     coc-eslint
  #     coc-pairs
  #     coc-prettier
  #     coc-rls
  #     coc-rust-analyzer
  #   ];
  #   coc = {
  #     enable = true;
  #     settings = {
  #       suggest = {
  #         noselect = true;
  #         enablePreview = true;
  #         enablePreselect = true;
  #         disableKind = true;
  #       };
  #     };
  #   };
  # };

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    colorschemes.catppuccin.enable = true;
    clipboard = {
      providers.wl-copy.enable = true;
      register = "unnamedplus";
    };
    opts = {
      number = true;
      relativenumber = true;

      updatetime = 100; # faster completion

      # Intent
      expandtab = true; # \t to space conversion
      autoindent = true;
      smartindent = true;
      tabstop = 4;
      shiftwidth = 4;
    };

    extraPlugins = with pkgs.vimPlugins; [
    ];

    plugins = {
      auto-save.enable = true;
      lightline.enable = true;
      commentary.enable = true;
      comment.enable = true;

      # Visual
      airline.enable = true; # Status bar

      toggleterm = {
        enable = true;
        settings = {
          open_mapping = "[[<C-t>]]";
          start_in_insert = false;
        };
      };
      nvim-tree = {
        enable = true;
        openOnSetup = true;
        openOnSetupFile = true;
        autoReloadOnWrite = true;
      };

      # Rust stuff
      rustaceanvim = {
        enable = true;
        settings.server.default_settings = {
          cargo = {
            buildScripts = {
              enable = true;
            };
          };
          procMacro = {
            enable = true;
          };
        };
      };
      crates-nvim.enable = true;

      # Language servers
      lsp = {
        enable = true;
        servers = {
          rust-analyzer = {
            enable = true;
            installRustc = true;
            installCargo = true;
          };
          typst-lsp.enable = true;
          pylsp.enable = true;
        };
      };
      lsp-format.enable = true;

      # Copilot
      copilot-lua = {
        enable = true;

        suggestion.enabled = false;
        panel.enabled = false;
      };
      copilot-cmp.enable = true;

      # cmp plugins
      cmp.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp-buffer.enable = true;
      cmp-git.enable = true;
      cmp-clippy.enable = true;
      cmp-spell.enable = true;
      cmp-tmux.enable = true;
      cmp-emoji.enable = true;

      # git
      # trouble.enable = true;
      gitsigns = {
        enable = false;
        # settings = {
        #   current_line_blame = true;
        #   trouble = true;
        # };
      };

      # tree-sitter
      treesitter = {
        enable = true;
        nixGrammars = true;
        indent = true;
      };
      treesitter-context = {
        enable = true;
        settings = {max_lines = 2;};
      };
      rainbow-delimiters.enable = true;
      nvim-autopairs.enable = true;
    };
  };

  xdg.configFile."nvim/init.lua".text = ''
  '';
}
