{
  config,
  flakes,
  pkgs,
  unstable,
  lib,
  ...
}: let
  catppuccinVariant =
    if (config.stylix.polarity or "light") == "dark"
    then "mocha"
    else "latte";
  batTheme = "Catppuccin " + (
    if catppuccinVariant == "mocha" then "Mocha" else "Latte"
  );
in {
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
      bat
      harper
    ];
    languages = {
      language = [
        {
          name = "rust";
          auto-format = true;
        }
        {
          name = "markdown";
          language-servers = ["marksman" "harper-ls"];
          auto-pairs = {
            "(" = ")";
            "{" = "}";
            "\"" = "\"";
            "`" = "`";
          };
        }
        {
          name = "nix";
          auto-format = false;
        }
      ];
      language-server = {
        "harper-ls" = {
          command = "harper-ls";
          args = ["--stdio"];
        };
      };
    };
    settings = {
      theme = "catppuccin_${catppuccinVariant}";

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
          ":insert-output bat --paging=always --pager=less --theme='${batTheme}' --style=plain '%{buffer_name}' </dev/tty >/dev/tty 2>&1"
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
        j = {
          k = "normal_mode";
        };
      };
    };
  };

  # Steel plugins (loaded via init.scm on steelix startup)
  xdg.configFile."helix/plugins/vim-hx".source = flakes.vimhx;
  xdg.configFile."helix/plugins/wakatime".source = flakes.wakatimehx;
  xdg.configFile."helix/forest".source = flakes.foresthx;
  xdg.configFile."helix/notify".source = flakes.notifyhx;
  xdg.configFile."helix/glyph".source = flakes.glyphhx;
  xdg.configFile."helix/paragraph-delete.scm".text = ''
    ;; d} / d{ — cut from the cursor to the next/previous paragraph boundary.
    ;;
    ;; vim.hx registers the paragraph text-objects (dap/dip) and the bare
    ;; {/} jumps, but nothing under the `d` operator targets a paragraph
    ;; boundary. These mirror Vim's d}/d{: yank + delete the range the {/}
    ;; motion crosses.
    ;;
    ;; `goto_next_paragraph` only *moves* the cursor in normal mode, so we
    ;; capture the position before/after the jump and extend the selection
    ;; explicitly — the same pattern as vim.hx's vim-delete-prev-word.

    (require (prefix-in helix. "helix/commands.scm"))
    (require (prefix-in helix.static. "helix/static.scm"))
    (require "helix/editor.scm")
    (require "helix/misc.scm")
    (require "helix/keymaps.scm")
    (require "plugins/vim-hx/utils.scm")

    ;; d}
    (define (vim-delete-to-next-paragraph)
      (define pos (cursor-position))
      (helix.static.goto_next_paragraph)
      (define end-pos (cursor-position))
      (when (not (equal? end-pos pos))
        (move-to-position pos)
        (extend-to-position end-pos)
        (helix.clipboard-yank)
        (helix.static.delete_selection)))

    ;; d{
    (define (vim-delete-to-prev-paragraph)
      (define pos (cursor-position))
      (helix.static.goto_prev_paragraph)
      (define start-pos (cursor-position))
      (when (not (equal? start-pos pos))
        (move-to-position start-pos)
        (extend-to-position pos)
        (helix.clipboard-yank)
        (helix.static.delete_selection)))

    ;; Merges `}` and `{` into the `d` prefix node that set-vim-keybindings!
    ;; registered. add-global-keybinding merges recursively, so the
    ;; dd/dw/dap/... bindings are left intact. Must run after that call.
    (define (set-paragraph-delete-keybindings!)
      (add-global-keybinding
        (keymap (normal (d ("}" ":vim-delete-to-next-paragraph")
                           ("{" ":vim-delete-to-prev-paragraph"))))))

    (provide vim-delete-to-next-paragraph
             vim-delete-to-prev-paragraph
             set-paragraph-delete-keybindings!)
  '';

  xdg.configFile."helix/init.scm".text = ''
    (require "plugins/vim-hx/init.scm")
    (set-vim-keybindings!)
    (require "paragraph-delete.scm")
    (set-paragraph-delete-keybindings!)
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
