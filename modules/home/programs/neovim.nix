# References:
# https://github.com/azuwis/nix-config/blob/885e77f74bd730f37d715c6a7ed1a9269a619f7d/common/neovim/nvchad.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    neovide
  ];

  # https://github.com/tars0x9752/home/blob/main/modules/neovim/default.nix
  # https://github.com/notusknot/dotfiles-nix/blob/main/modules/nvim/default.nix
  programs.nixvim = {
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
      expandtab = true; # tab to space
      autoindent = true;
      smartindent = true;
      tabstop = 4;
      shiftwidth = 4;
    };
    keymaps = [
      # {
      #   action = ":NvimTreeToggle<CR>";
      #   key = "<C-n>";
      #   options = {
      #     noremap = true;
      #     silent = true;
      #   };
      # }
    ];
    performance = {
      byteCompileLua = {
        enable = true;
        configs = true;
        initLua = true;
        nvimRuntime = true;
        plugins = true;
      };
    };
    plugins = {
      auto-save.enable = true;
      lightline.enable = true;
      commentary.enable = true;
      comment.enable = true;
      todo-comments.enable = true;
      rainbow-delimiters.enable = true;
      autoclose.enable = true;
      direnv.enable = true;

      # Misc
      dashboard.enable = true;
      obsidian = {
        enable = true;
        settings = {
          completion = {
            min_chars = 2;
            nvim_cmp = true;
          };
          workspaces = [
            {
              name = "temp";
              path = "~/Documents/temp";
            }
          ];
        };
      };

      # Fuzzy finder
      telescope = {
        enable = true;
        autoLoad = true;
        keymaps = {
          # l = live_grep
          # f = find_files
          # a = file_browser
          # g = git_commits
          "<C-p>" = "find_files";
          "<C-l>" = "live_grep";
          "<space>ff" = "find_files";
          "<space>fg" = "live_grep";
        };
      };

      # Visual
      fidget.enable = true; # LSP status
      airline.enable = true; # Status bar

      toggleterm = {
        enable = true;
        settings = {
          open_mapping = "[[<C-t>]]";
        };
      };
      nvim-tree = {
        enable = true;
        openOnSetup = true;
        # TODO: Setup keybinds + don't show per default
      };
      web-devicons.enable = true;

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

            diagnostics = {
              enable = true;
              styleLints.enable = true;
            };

            checkOnSave = true;
            check = {
              command = "clippy";
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

            inlayHints = {
              bindingModeHints.enable = true;
              closureStyle = "rust_analyzer";
              closureReturnTypeHints.enable = "always";
              discriminantHints.enable = "always";
              expressionAdjustmentHints.enable = "always";
              implicitDrops.enable = true;
              lifetimeElisionHints.enable = "always";
              rangeExclusiveHints.enable = true;
            };

            procMacro = {
              enable = true;
            };

            rustc.source = "discover";
          };
        };
      };
      crates.enable = true;

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
      lsp-format = {
        enable = false;
        settings = {
          nix = {};
          rust = {};
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
            model = "claude-3.5-sonnet";
          };
          file_selector = {
            provider = "fzf";
            provider_opts = {};
          };
        };
      };
      copilot-lua = {
        enable = true;
        settings.suggestion = {
          enabled = true;
          auto_trigger = true;
          debounce = 90;
          keymap = {
            accept = "<Tab>";
          };
        };
        settings.panel.enable = false;
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

      nix.enable = true;

      # git
      trouble.enable = true;
      gitsigns.enable = true;

      # tree-sitter
      treesitter = {
        enable = true;
        folding = false;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };
      treesitter-context = {
        enable = true;
        settings = {max_lines = 2;};
      };
      nvim-autopairs.enable = true;
    };
  };

  xdg.configFile."nvim/init.lua".text = ''
  '';
}
