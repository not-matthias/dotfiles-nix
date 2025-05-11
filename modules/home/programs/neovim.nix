# References:
# https://github.com/azuwis/nix-config/blob/885e77f74bd730f37d715c6a7ed1a9269a619f7d/common/neovim/nvchad.nix
{
  # https://github.com/tars0x9752/home/blob/main/modules/neovim/default.nix
  # https://github.com/notusknot/dotfiles-nix/blob/main/modules/nvim/default.nix
  programs.nixvim = {
    defaultEditor = true;
    colorschemes.ayu = {
      settings.mirage = false;
      enable = true;
    };
    clipboard = {
      providers.wl-copy.enable = true;
      register = "unnamedplus";
    };
    opts = {
      number = true;
      relativenumber = true;

      # Intent
      expandtab = true; # tab to space
      autoindent = true;
      smartindent = true;
      tabstop = 4;
      shiftwidth = 4;
    };
    keymaps = [
      # {
      #   mode = "t";
      #   key = "<C-/>";
      #   action = "<cmd>close<cr>";
      #   options = {
      #     desc = "Hide Terminal";
      #   };
      # }
      {
        mode = "n";
        key = "<space>fb";
        action = "<cmd>:NvimTreeToggle<cr>";
        options = {
          silent = true;
          desc = "Toggle file manager";
        };
      }
    ];
    luaLoader.enable = true;
    plugins = {
      # Old stuff:
      # Yazi

      auto-save.enable = true;
      lightline.enable = true;
      # commentary.enable = true;
      # comment.enable = true;
      todo-comments.enable = true;
      rainbow-delimiters.enable = true;
      autoclose.enable = true;
      direnv.enable = true;
      persistence.enable = true;
      # bullets.enable = true;
      nvim-autopairs.enable = true;
      diffview.enable = true;
      zen-mode.enable = true;

      # Learn neovim better
      which-key = {
        enable = true;
        settings = {
          notify = true;
          preset = "helix";
        };
      };

      # Fuzzy finder
      telescope = {
        enable = true;
        keymaps = {
          "<space>ff" = "find_files";
          "<space>fg" = "live_grep";
          "<space>fk" = "keymaps";
          "<space>ft" = "colorscheme";
          "<space>fe" = "file_browser";
          "<space>fc" = "git_commits";
        };
        extensions = {
          file-browser.enable = true;
        };
      };

      # Visual
      fidget.enable = true; # LSP status
      airline.enable = true; # Status bar
      web-devicons.enable = true;

      # Warnings and notifications
      noice = {
        enable = true;
        settings = {
          notify.enabled = true;
          messages.enabled = true;
        };
      };
      notify.enable = true;

      nvim-tree = {
        enable = true;
        filters = {
        };
        git = {
          enable = true;
          ignore = false;
        };
        modified.enable = true;
      };

      # TODO: Setup dap-rr, dap-ui, ...

      # Rust stuff
      # TODO: Allow inline hints + copilot
      rustaceanvim = {
        enable = true;
        settings.server.default_settings = {
          rust-analyzer = {
            cargo = {
              buildScripts.enable = true;
              features = "all";
            };

            files = {
              excludeDirs = [
                ".cargo"
                ".direnv"
                ".git"
                "node_modules"
                "target"
              ];
            };
          };
        };
      };
      # crates.enable = true;

      # Language servers
      lsp = {
        enable = true;
        inlayHints = true;
        servers = {
          nixd.enable = true;
          pylsp.enable = true;
          beancount.enable = true;
          # rust_analyzer.enable = true;
        };
      };

      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_format = "fallback";
            timeout_ms = 500;
          };
          formatters_by_ft = {
            nix = ["alejandra"];
            rust = ["rustfmt"];
            sh = ["shfmt"];
            javascript = ["prettier"];
            javascriptreact = ["prettier"];
            typescript = ["prettier"];
            typescriptreact = ["prettier"];
            svelte = ["prettier"];
            css = ["prettier"];
            html = ["prettier"];
            json = ["prettier"];
            yaml = ["prettier"];
            markdown = ["prettier"];
            typst = ["typstfmt"];
          };
        };
      };

      # Copilot
      avante = {
        enable = true;
        settings = {
          provider = "copilot";
          auto_suggestions_frequency = "copilot";
          copilot = {
            model = "claude-3.7-sonnet";
          };
          file_selector = {
            provider = "fzf";
            provider_opts = {};
          };
        };
      };
      copilot-lua = {
        enable = true;
        # settings.suggestion = {
        #   enabled = true;
        #   auto_trigger = true;
        #   debounce = 90;
        #   keymap = {
        #     accept = "<Tab>";
        #   };
        # };
        # settings.panel.enable = false;
      };
      # copilot-cmp.enable = true;

      # blink-cmp = {
      #   enable = true;
      #   settings.sources.default = [
      #     "lsp"
      #     "path"
      #     "luasnip"
      #     "buffer"
      #     "copilot"
      #   ];
      # };
      # blink-cmp-copilot.enable = true;
      # blink-cmp-dictionary.enable = true;
      # blink-cmp-git.enable = true;
      # blink-cmp-spell.enable = true;
      # blink-compat.enable = true;

      nix.enable = true;

      # git
      trouble.enable = true;
      gitsigns.enable = true;

      # tree-sitter
      treesitter = {
        enable = true;
      };
    };
  };

  xdg.configFile."nvim/init.lua".text = ''
  '';
}
