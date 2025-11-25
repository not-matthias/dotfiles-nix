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
      # ============================================================================
      # CODE NAVIGATION (JetBrains style)
      # ============================================================================
      {
        mode = "n";
        key = "gd";
        action = "<cmd>Telescope lsp_definitions<cr>";
        options = {
          silent = true;
          desc = "Go to definition";
        };
      }
      {
        mode = "n";
        key = "<C-b>";
        action = "<cmd>Telescope lsp_definitions<cr>";
        options = {
          silent = true;
          desc = "Go to definition (Ctrl+B)";
        };
      }
      {
        mode = "n";
        key = "gD";
        action = "<cmd>Telescope lsp_declarations<cr>";
        options = {
          silent = true;
          desc = "Go to declaration";
        };
      }
      {
        mode = "n";
        key = "gi";
        action = "<cmd>Telescope lsp_implementations<cr>";
        options = {
          silent = true;
          desc = "Go to implementation";
        };
      }
      {
        mode = "n";
        key = "gy";
        action = "<cmd>Telescope lsp_type_definitions<cr>";
        options = {
          silent = true;
          desc = "Go to type definition";
        };
      }
      {
        mode = "n";
        key = "<C-A-Left>";
        action = "<cmd>execute 'normal! ' . v:count1 . '<C-o>'<cr>";
        options = {
          silent = true;
          desc = "Navigate back";
        };
      }
      {
        mode = "n";
        key = "<C-A-Right>";
        action = "<cmd>execute 'normal! ' . v:count1 . '<C-i>'<cr>";
        options = {
          silent = true;
          desc = "Navigate forward";
        };
      }
      {
        mode = "n";
        key = "<S-F12>";
        action = "<cmd>Telescope lsp_references<cr>";
        options = {
          silent = true;
          desc = "Find usages/references";
        };
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<cmd>Trouble lsp<cr>";
        options = {
          silent = true;
          desc = "Show call hierarchy";
        };
      }

      # ============================================================================
      # WINDOW MANAGEMENT (remapped from Ctrl+W to Space+W)
      # ============================================================================
      {
        mode = "n";
        key = "<space>ww";
        action = "<C-w>w";
        options = {
          silent = true;
          desc = "Switch window";
        };
      }
      {
        mode = "n";
        key = "<space>wh";
        action = "<C-w>h";
        options = {
          silent = true;
          desc = "Move to left window";
        };
      }
      {
        mode = "n";
        key = "<space>wj";
        action = "<C-w>j";
        options = {
          silent = true;
          desc = "Move to below window";
        };
      }
      {
        mode = "n";
        key = "<space>wk";
        action = "<C-w>k";
        options = {
          silent = true;
          desc = "Move to above window";
        };
      }
      {
        mode = "n";
        key = "<space>wl";
        action = "<C-w>l";
        options = {
          silent = true;
          desc = "Move to right window";
        };
      }
      {
        mode = "n";
        key = "<space>wd";
        action = "<C-w>c";
        options = {
          silent = true;
          desc = "Delete/close window";
        };
      }
      {
        mode = "n";
        key = "<space>wv";
        action = "<C-w>v";
        options = {
          silent = true;
          desc = "Split window vertically";
        };
      }
      {
        mode = "n";
        key = "<space>ws";
        action = "<C-w>s";
        options = {
          silent = true;
          desc = "Split window horizontally";
        };
      }
      {
        mode = "n";
        key = "<C-w>d";
        action = "<nop>";
        options = {
          silent = true;
          desc = "Unbind diagnostic shortcut";
        };
      }
      {
        mode = "n";
        key = "<C-w>c";
        action = "<nop>";
        options = {
          silent = true;
          desc = "Unbind diagnostic shortcut";
        };
      }

      # ============================================================================
      # CODE ACTIONS & REFACTORING
      # ============================================================================
      {
        mode = "n";
        key = "<F2>";
        action = "<cmd>lua vim.lsp.buf.rename()<cr>";
        options = {
          silent = true;
          desc = "Rename symbol";
        };
      }
      {
        mode = "n";
        key = "<S-F6>";
        action = "<cmd>lua vim.lsp.buf.rename()<cr>";
        options = {
          silent = true;
          desc = "Rename symbol (Shift+F6)";
        };
      }
      {
        mode = "n";
        key = "<C-A-l>";
        action = "<cmd>lua vim.lsp.buf.format()<cr>";
        options = {
          silent = true;
          desc = "Format document";
        };
      }
      {
        mode = "v";
        key = "<C-A-l>";
        action = "<cmd>lua vim.lsp.buf.format()<cr>";
        options = {
          silent = true;
          desc = "Format selection";
        };
      }
      {
        mode = "n";
        key = "<C-A-o>";
        action = "<cmd>Lspsaga code_action<cr>";
        options = {
          silent = true;
          desc = "Organize imports / code actions";
        };
      }

      # ============================================================================
      # SEARCH & FIND
      # ============================================================================
      {
        mode = "n";
        key = "<C-o>";
        action = "<cmd>Telescope find_files<cr>";
        options = {
          silent = true;
          desc = "Open file";
        };
      }
      {
        mode = "n";
        key = "<C-S-f>";
        action = "<cmd>Telescope live_grep<cr>";
        options = {
          silent = true;
          desc = "Find in files";
        };
      }
      {
        mode = "n";
        key = "<C-f>";
        action = "<cmd>Telescope current_buffer_fuzzy_find<cr>";
        options = {
          silent = true;
          desc = "Find in current buffer";
        };
      }
      {
        mode = "n";
        key = "<C-S-n>";
        action = "<cmd>Telescope lsp_document_symbols<cr>";
        options = {
          silent = true;
          desc = "Find symbol in buffer";
        };
      }
      {
        mode = "n";
        key = "<C-S-a>";
        action = "<cmd>Telescope commands<cr>";
        options = {
          silent = true;
          desc = "Find action (command palette)";
        };
      }

      # ============================================================================
      # EDITOR ACTIONS
      # ============================================================================
      {
        mode = "n";
        key = "<C-d>";
        action = "<cmd>normal! yyp<cr>";
        options = {
          silent = true;
          desc = "Duplicate line";
        };
      }
      {
        mode = "v";
        key = "<C-d>";
        action = "<cmd>normal! y`>p<cr>";
        options = {
          silent = true;
          desc = "Duplicate selection";
        };
      }
      {
        mode = "n";
        key = "<C-/>";
        action = "<Plug>(comment_toggle_linewise_current)";
        options = {
          desc = "Toggle line comment";
        };
      }
      {
        mode = "v";
        key = "<C-/>";
        action = "<Plug>(comment_toggle_linewise_visual)";
        options = {
          desc = "Toggle block comment";
        };
      }

      # ============================================================================
      # TAB/BUFFER MANAGEMENT
      # ============================================================================
      {
        mode = "n";
        key = "<C-Tab>";
        action = "<cmd>BufferLineCycleNext<cr>";
        options = {
          silent = true;
          desc = "Next buffer/tab";
        };
      }
      {
        mode = "n";
        key = "<C-S-Tab>";
        action = "<cmd>BufferLineCyclePrev<cr>";
        options = {
          silent = true;
          desc = "Previous buffer/tab";
        };
      }
      {
        mode = "n";
        key = "<C-t>";
        action = "<cmd>enew<cr>";
        options = {
          silent = true;
          desc = "New buffer/tab";
        };
      }
      {
        mode = "n";
        key = "<C-w>";
        action = "<cmd>bdelete<cr>";
        options = {
          silent = true;
          desc = "Close buffer/tab";
        };
      }
      {
        mode = "n";
        key = "<C-S-t>";
        action = "<cmd>BufferLineGroupClose ungrouped<cr>";
        options = {
          silent = true;
          desc = "Reopen closed buffer";
        };
      }

      # ============================================================================
      # TERMINAL
      # ============================================================================
      {
        mode = "n";
        key = "<C-`>";
        action = "<cmd>ToggleTerm<cr>";
        options = {
          silent = true;
          desc = "Toggle terminal";
        };
      }
      {
        mode = "t";
        key = "<C-`>";
        action = "<cmd>ToggleTerm<cr>";
        options = {
          silent = true;
          desc = "Toggle terminal (from terminal mode)";
        };
      }
      {
        mode = "n";
        key = "<C-F12>";
        action = "<cmd>ToggleTerm<cr>";
        options = {
          silent = true;
          desc = "Toggle terminal";
        };
      }
      {
        mode = "t";
        key = "<C-F12>";
        action = "<cmd>ToggleTerm<cr>";
        options = {
          silent = true;
          desc = "Toggle terminal (from terminal mode)";
        };
      }
      {
        mode = "n";
        key = "<C-S-F12>";
        action = "<cmd>ToggleTerm size=40 direction=float<cr>";
        options = {
          silent = true;
          desc = "New floating terminal";
        };
      }

      # ============================================================================
      # TOOL WINDOWS (using Ctrl since Alt is reserved for window manager)
      # ============================================================================
      {
        mode = "n";
        key = "<C-1>";
        action = "<cmd>NvimTreeToggle<cr>";
        options = {
          silent = true;
          desc = "Toggle file explorer";
        };
      }
      {
        mode = "n";
        key = "<C-9>";
        action = "<cmd>Neogit<cr>";
        options = {
          silent = true;
          desc = "Toggle Git (Neogit)";
        };
      }
      {
        mode = "n";
        key = "<C-a>";
        action = "<cmd>AerialToggle<cr>";
        options = {
          silent = true;
          desc = "Toggle symbol outline";
        };
      }
      {
        mode = "n";
        key = "<C-u>";
        action = "<cmd>UndotreeToggle<cr>";
        options = {
          silent = true;
          desc = "Toggle undo tree";
        };
      }

      # ============================================================================
      # LEGACY SPACE-BASED KEYBINDS (preserved for compatibility)
      # ============================================================================
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

      # Session management
      auto-session = {
        enable = false;
        settings = {
          auto_save_enabled = true;
          auto_restore_enabled = true;
          auto_session_suppress_dirs = [
            "~/"
            "~/Projects"
            "/tmp"
          ];
        };
      };

      # QoL
      easyescape.enable = true;
      lastplace.enable = true;
      snacks.enable = true;
      undotree.enable = true;
      dashboard.enable = true;
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
          modes.char.enabled = true;
          labels = "asdfghjklqwertyuiopzxcvbnm";
          continue = false;
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
            action = "live_grep";
            options.desc = "Live grep";
          };
          "<space>gg" = "git_files";
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
          views = {
            notify = {
              replace = true;
              max_height = 2;
            };
          };
          routes = [
            {
              filter = {event = "msg_show";};
              view = "mini";
            }
          ];
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

      # Code actions and refactoring UI
      lspsaga.enable = true;

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

      # Claude Code integration
      # claude-code.enable = true;

      # Time tracking
      wakatime.enable = true;

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
