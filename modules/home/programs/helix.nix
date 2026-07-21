{
  config,
  flakes,
  pkgs,
  unstable,
  lib,
  ...
}: {
  stylix.targets.helix.enable = false;

  programs.helix = {
    enable = true;
    package = unstable.steelix;
    extraPackages = with pkgs; [
      marksman
      nixd
      rust-analyzer
      taplo
      wakatime-cli
      glow
    ];
    languages = {
      language = [
        {
          name = "rust";
          auto-format = true;
        }
        {
          name = "nix";
          auto-format = false;
        }
      ];
    };
    settings = {
      theme = "catppuccin_latte";

      editor = {
        bufferline = "multiple";
        cursorline = true;
        line-number = "relative";
        rulers = [120];
        popup-border = "all";
        trim-trailing-whitespace = true;
        insert-final-newline = true;
        end-of-line-diagnostics = "hint";
        rainbow-brackets = true;

        auto-completion = true;
        completion-trigger-len = 2;
        completion-timeout = 5;
        continue-comments = true;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides = {
          render = true;
          character = "╎";
          skip-levels = 1;
        };

        lsp = {
          display-messages = true;
          auto-signature-help = false;
          display-inlay-hints = true;
        };

        statusline = {
          # TODO: Update this and make it more minimal
          left = [
            "mode"
            "file-name"
          ];
          right = [
            "diagnostics"
            "selections"
            "position"
            "file-encoding"
            "file-line-ending"
          ];
        };

        inline-diagnostics = {
          cursor-line = "error";
          other-lines = "disable";
        };
        soft-wrap.enable = true;

        auto-save = {
          after-delay = {
            enable = true;
            timeout = 3000;
          };
        };
      };

      keys.normal = {
        space.space = "file_picker";
        space.h = ":toggle file-picker.hidden";
        space.e = ":forest-open";
        space.y = [
          ":sh rm -f /tmp/yazi-chooser"
          ":insert-output yazi '%{buffer_name}' --chooser-file=/tmp/yazi-chooser"
          '':sh printf "\x1b[?1049h\x1b[?2004h" > /dev/tty''
          ":open %sh{cat /tmp/yazi-chooser}"
          ":redraw"
        ];
        space.g.u = [
          ":insert-output gitui </dev/tty >/dev/tty 2>&1"
          '':sh printf "\x1b[?1049h\x1b[?2004h" > /dev/tty''
          ":redraw"
        ];
        space.m = [
          ":write"
          ":insert-output glow -s ${config.stylix.polarity} -p '%{buffer_name}' </dev/tty >/dev/tty 2>&1"
          '':sh printf "\x1b[?1049h\x1b[?2004h" > /dev/tty''
          ":redraw"
        ];
        space.w = ":w";
        space.q = ":q";
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
        "A-," = "goto_previous_buffer";
        "A-." = "goto_next_buffer";
        "A-w" = ":buffer-close";
        "C-c" = "no_op";
      };
      keys.insert = {
        "C-c" = "normal_mode";
      };
    };
  };

  # Steel plugins (loaded via init.scm on steelix startup)
  xdg.configFile."helix/plugins/vim-hx".source = flakes.vimhx;
  xdg.configFile."helix/plugins/wakatime".source = flakes.wakatimehx;
  xdg.configFile."helix/forest".source = flakes.foresthx;
  xdg.configFile."helix/notify".source = flakes.notifyhx;
  xdg.configFile."helix/glyph".source = flakes.glyphhx;
  xdg.configFile."helix/init.scm".text = ''
    (require "plugins/vim-hx/init.scm")
    (set-vim-keybindings!)
    (require "plugins/wakatime/wakatime.scm")
    (require "forest/forest.scm")
  '';

  # The nixpkgs helix-runtime may ship grammars and queries from mismatched
  # tree-sitter versions, causing highlight compilation to fail. Build from
  # source as a fallback when prebuilt grammars are missing.
  home.activation.buildHelixGrammars = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -e "$HOME/.config/helix/runtime/grammars/rust.so" ]; then
      export PATH=${lib.makeBinPath [pkgs.git pkgs.gcc]}:$PATH
      $DRY_RUN_CMD ${unstable.steelix}/bin/hx --grammar fetch
      $DRY_RUN_CMD ${unstable.steelix}/bin/hx --grammar build
    fi
  '';
}
