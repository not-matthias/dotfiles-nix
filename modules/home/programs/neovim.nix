# References:
# https://github.com/azuwis/nix-config/blob/885e77f74bd730f37d715c6a7ed1a9269a619f7d/common/neovim/nvchad.nix
{
  # https://github.com/tars0x9752/home/blob/main/modules/neovim/default.nix
  # https://github.com/notusknot/dotfiles-nix/blob/main/modules/nvim/default.nix
  programs.nixvim = {
    defaultEditor = true;
    colorschemes.catppuccin = {
      settings.flavour = "latte";
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
      {
        mode = "n";
        key = "<space>gg";
        action = "<cmd>Neogit<cr>";
        options = {
          desc = "Git status (Neogit)";
        };
      }
      {
        mode = "n";
        key = "<space>gb";
        action = "<cmd>GitBlameToggle<cr>";
        options = {
          desc = "Toggle git blame";
        };
      }
      {
        mode = "n";
        key = "<space>u";
        action = "<cmd>UndotreeToggle<cr>";
        options = {
          desc = "Undo tree";
        };
      }
      {
        mode = "n";
        key = "<space>a";
        action = "<cmd>AerialToggle<cr>";
        options = {
          desc = "Symbol outline";
        };
      }
    ];
    luaLoader.enable = true;
    plugins = {
      # Old stuff:
      # Yazi

      auto-save.enable = true;
      autoclose.enable = true;
      commentary.enable = true;
      comment.enable = true;
      todo-comments.enable = true;
      rainbow-delimiters.enable = true;
      direnv.enable = true;
      persistence.enable = true;
      # bullets.enable = true;
      nvim-autopairs.enable = true;
      diffview.enable = true;
      zen-mode.enable = true;
      bufferline.enable = true;
      toggleterm.enable = true;

      # QoL
      lastplace.enable = true;
      snacks.enable = true;
      undotree.enable = true;
      aerial = {
        enable = true;
        settings = {
          backends = ["treesitter" "lsp"];
          layout = {
            default_direction = "prefer_right";
            placement = "edge";
          };
        };
      };
      flash = {
        enable = true;
        settings = {
          modes.char.enabled = false; # Don't override f/F/t/T
        };
      };

      # Learn neovim better
      which-key = {
        enable = true;
        settings = {
          notify = true;
          preset = "modern";
        };
      };

      # Fuzzy finder
      telescope = {
        enable = true;
        keymaps = {
          "<space>ff" = {
            action = "find_files";
            options.desc = "Find files (including hidden)";
          };
          "<space>fg" = {
            action = "git_files";
            options.desc = "Find git files";
          };
          "<space>gg" = "live_grep";
          "<space>lg" = "live_grep";
          "<space>fk" = "keymaps";
          "<space>ft" = "colorscheme";
          "<space>fe" = "file_browser";
          "<space>fc" = "git_commits";
        };
        settings.defaults.file_ignore_patterns = [];
        settings.pickers.find_files = {
          hidden = true;
          no_ignore = true;
        };
        extensions = {
          file-browser.enable = true;
        };
      };

      # Visual
      fidget.enable = true; # LSP status
      web-devicons.enable = true;
      indent-blankline = {
        enable = true;
        settings = {
          scope.enabled = true;
        };
      };
      tiny-inline-diagnostic = {
        enable = true;
        settings = {
          preset = "modern";
        };
      };

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
        enable = false;
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

      blink-cmp = {
        enable = true;
        settings.sources.default = [
          "lsp"
          "path"
          "buffer"
        ];
      };
      blink-copilot.enable = true;
      blink-cmp-copilot.enable = true;
      blink-cmp-dictionary.enable = true;
      blink-cmp-git.enable = true;
      blink-cmp-spell.enable = true;
      blink-compat.enable = true;

      nix.enable = true;

      # git
      trouble.enable = true;
      gitsigns.enable = true;
      neogit = {
        enable = true;
        settings = {
          integrations = {
            diffview = true;
            telescope = true;
          };
        };
      };
      gitblame = {
        enable = true;
        settings = {
          enabled = false; # Don't show by default, toggle with keybind
          message_template = "<author> • <date> • <summary>";
          date_format = "%r";
        };
      };

      # tree-sitter
      treesitter = {
        enable = true;
      };
    };
  };
}
