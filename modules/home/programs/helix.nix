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
  glowStyle =
    if catppuccinVariant == "mocha"
    then "dark"
    else "light";
in {
  options.programs.helix.compat.enable = lib.mkEnableOption "the nvim compatibility alias";
  config = {
    stylix.targets.helix.enable = false;
    programs.fish.shellAbbrs.h = "hx .";
    programs.fish.shellAliases.nvim = lib.mkIf config.programs.helix.compat.enable "hx";

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
            ":insert-output glow --pager --style=${glowStyle} '%{buffer_name}' </dev/tty >/dev/tty 2>&1"
            '':sh printf "\x1b[?1049h\x1b[?2004h" > /dev/tty''
            ":redraw"
          ];
          space.w = ":w";
          space.q = ":q";
          space.f.b = "file_explorer";
          space.f.e = "file_explorer_in_current_buffer_directory";
          space.a = "lsp_or_syntax_symbol_picker";
          "C-1" = "file_explorer";
          # Neovim-compatible aliases for actions Helix already provides.
          g.c.c = "toggle_line_comments";
          g.b.c = "toggle_block_comments";
          g.d = "goto_definition";
          g.D = "goto_declaration";
          g.i = "goto_implementation";
          g.y = "goto_type_definition";
          g.r.r = "goto_reference";
          g.r.a = "code_action";
          g.r.n = "rename_symbol";
          K = "hover";
          "C-/" = "toggle_line_comments";
          "C-p" = "file_picker";
          "C-b" = "goto_definition";
          "C-S-f" = "global_search";
          "C-S-n" = "lsp_or_syntax_symbol_picker";
          "C-S-p" = "command_palette";
          "C-tab" = "goto_next_buffer";
          "C-S-tab" = "goto_previous_buffer";
          "C-A-left" = "jump_backward";
          "C-A-right" = "jump_forward";
          "C-A-l" = ":format";
          "C-A-o" = "code_action";
          "S-F12" = "goto_reference";
          "F2" = "rename_symbol";
          "S-F6" = "rename_symbol";
          # gc{motion} mirrors Commentary for the supported vim.hx motions.
          esc = [
            "collapse_selection"
            "keep_primary_selection"
          ];
          "A-w" = ":buffer-close";
          "C-c" = "no_op";
        };
        keys.select = {
          g.c = "toggle_line_comments";
          g.b = "toggle_block_comments";
          "C-/" = "toggle_line_comments";
          "C-A-l" = "format_selections";
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

    xdg.configFile."helix/vim-fixes.scm".text = ''
      ;; Missing and broken vim.hx keybindings.
      ;;
      ;; The vim-hx plugin is a read-only Nix store symlink. All fixes go here
      ;; and are loaded after set-vim-keybindings! in init.scm. See
      ;; paragraph-delete.scm for the same overlay pattern.
      ;;
      ;; Fixes:
      ;; 1. 14 yank text object functions referenced in the vim-hx keymap but
      ;;    never defined in yank-motions.scm (yap/yip/yaf/yif/yac/yic/yae/yie/
      ;;    yax/yix/yat/yit/yaT/yiT) — pressing them was a silent no-op.
      ;; 2. Yank bracket/quote text objects: 12 functions + 20 keymap entries
      ;;    (opening and closing aliases). Delete and change had them; yank had
      ;;    none, so yi{/ya(/yi" etc. were not even parsed.
      ;; 3. ye/yE bug — mapped to yank-word (yanks to word START) instead of
      ;;    yanking to word END.
      ;; 4. Closing-bracket aliases }/]/)/> for the a/i text-object nodes under
      ;;    d and c.
      ;; 5. Linewise file-boundary operator motions: yG/ygg, dG/dgg,
      ;;    cG/cgg, >G/>gg and <G/<gg.
      ;;
      ;; Not fixed (upstream TODOs in vim-hx):
      ;; - Long-WORD text objects (daW/diW/caW/ciW/yaW/yiW) — commented out in
      ;;   delete-motions.scm:102-111 and change-motions.scm:66-75
      ;; - Backtick text objects — only " and ' are wired in visual-motions.scm

      (require (prefix-in helix.static. "helix/static.scm"))
      (require (prefix-in helix. "helix/commands.scm"))

      (require "helix/keymaps.scm")
      (require "plugins/vim-hx/visual-motions.scm")
      (require "plugins/vim-hx/utils.scm")
      (require "helix/misc.scm")
      (require "helix/components.scm")
      (require "helix/editor.scm")
      ;; Yank helper — mirrors yank-impl from yank-motions.scm (not exported)
      (define (vim-yank-impl func)
        (func)
        (helix.static.yank_main_selection_to_clipboard)
        (helix.static.flip_selections)
        (helix.static.collapse_selection))

      ;; File-boundary motions for operators — yG/ygg, dG/dgg, and cG/cgg.
      ;; Extending to the file boundary first, then to line bounds, keeps
      ;; these G/gg motions linewise in either direction.
      (define (extend-line-to-file-end)
        (helix.static.extend_to_file_end)
        (helix.static.extend_to_line_bounds))

      (define (extend-line-to-file-start)
        (helix.static.extend_to_file_start)
        (helix.static.extend_to_line_bounds))

      (define (vim-delete-impl func)
        (func)
        (helix.clipboard-yank)
        (helix.static.delete_selection))

      (define (vim-change-impl func)
        (func)
        (helix.clipboard-yank)
        (helix.static.change_selection))

      (define (vim-indent-impl func)
        (func)
        (helix.static.indent)
        (helix.static.collapse_selection))

      (define (vim-unindent-impl func)
        (func)
        (helix.static.unindent)
        (helix.static.collapse_selection))

      (define (yank-file-end) (vim-yank-impl extend-line-to-file-end))
      (define (yank-file-start) (vim-yank-impl extend-line-to-file-start))
      (define (vim-delete-file-end) (vim-delete-impl extend-line-to-file-end))
      (define (vim-delete-file-start) (vim-delete-impl extend-line-to-file-start))
      (define (vim-change-file-end) (vim-change-impl extend-line-to-file-end))
      (define (vim-change-file-start) (vim-change-impl extend-line-to-file-start))
      (define (vim-indent-file-end) (vim-indent-impl extend-line-to-file-end))
      (define (vim-indent-file-start) (vim-indent-impl extend-line-to-file-start))
      (define (vim-unindent-file-end) (vim-unindent-impl extend-line-to-file-end))
      (define (vim-unindent-file-start) (vim-unindent-impl extend-line-to-file-start))
      ;; Comment.nvim-compatible `gc{motion}` operator.
      (define (vim-comment-impl func)
        (func)
        (helix.static.toggle_line_comments)
        (helix.static.collapse_selection))

      (define (extend-next-word-for-comment)
        (helix.static.extend_next_word_start)
        (set-editor-count! 1)
        (helix.static.extend_char_left))

      (define (extend-next-long-word-for-comment)
        (helix.static.extend_next_long_word_start)
        (set-editor-count! 1)
        (helix.static.extend_char_left))

      (define (vim-comment-counted-line-impl toggle)
        (define count (editor-count))
        (when (> count 1)
          (set-editor-count! (- count 1))
          (helix.static.extend_line_down))
        (helix.static.extend_to_line_bounds)
        (toggle)
        (helix.static.collapse_selection))

      (define (vim-comment-line)
        (vim-comment-counted-line-impl helix.static.toggle_line_comments))
      (define (vim-comment-block-line)
        (vim-comment-counted-line-impl helix.static.toggle_block_comments))
      (define (vim-comment-word) (vim-comment-impl extend-next-word-for-comment))
      (define (vim-comment-long-word) (vim-comment-impl extend-next-long-word-for-comment))
      (define (vim-comment-prev-word) (vim-comment-impl helix.static.extend_prev_word_start))
      (define (vim-comment-prev-long-word) (vim-comment-impl helix.static.extend_prev_long_word_start))
      (define (vim-comment-word-end) (vim-comment-impl helix.static.extend_next_word_end))
      (define (vim-comment-long-word-end) (vim-comment-impl helix.static.extend_next_long_word_end))
      (define (vim-comment-line-end) (vim-comment-impl helix.static.extend_to_line_end))
      (define (vim-comment-line-start) (vim-comment-impl helix.static.extend_to_line_start))
      (define (vim-comment-first-nonwhitespace) (vim-comment-impl helix.static.extend_to_first_nonwhitespace))
      (define (vim-comment-file-end) (vim-comment-impl extend-line-to-file-end))
      (define (vim-comment-file-start) (vim-comment-impl extend-line-to-file-start))

      (define (vim-comment-around-word) (vim-comment-impl select-around-word))
      (define (vim-comment-inner-word) (vim-comment-impl select-inner-word))
      (define (vim-comment-around-paragraph) (vim-comment-impl select-around-paragraph))
      (define (vim-comment-inner-paragraph) (vim-comment-impl select-inner-paragraph))
      (define (vim-comment-around-function) (vim-comment-impl select-around-function))
      (define (vim-comment-inner-function) (vim-comment-impl select-inner-function))
      (define (vim-comment-around-comment) (vim-comment-impl select-around-comment))
      (define (vim-comment-inner-comment) (vim-comment-impl select-inner-comment))
      (define (vim-comment-around-data-structure) (vim-comment-impl select-around-data-structure))
      (define (vim-comment-inner-data-structure) (vim-comment-impl select-inner-data-structure))
      (define (vim-comment-around-html-tag) (vim-comment-impl select-around-html-tag))
      (define (vim-comment-inner-html-tag) (vim-comment-impl select-inner-html-tag))
      (define (vim-comment-around-type-definition) (vim-comment-impl select-around-type-definition))
      (define (vim-comment-inner-type-definition) (vim-comment-impl select-inner-type-definition))
      (define (vim-comment-around-test) (vim-comment-impl select-around-test))
      (define (vim-comment-inner-test) (vim-comment-impl select-inner-test))
      (define (vim-comment-around-curly) (vim-comment-impl select-around-curly))
      (define (vim-comment-inner-curly) (vim-comment-impl select-inner-curly))
      (define (vim-comment-around-square) (vim-comment-impl select-around-square))
      (define (vim-comment-inner-square) (vim-comment-impl select-inner-square))
      (define (vim-comment-around-paren) (vim-comment-impl select-around-paren))
      (define (vim-comment-inner-paren) (vim-comment-impl select-inner-paren))
      (define (vim-comment-around-arrow) (vim-comment-impl select-around-arrow))
      (define (vim-comment-inner-arrow) (vim-comment-impl select-inner-arrow))
      (define (vim-comment-around-double-quote) (vim-comment-impl select-around-double-quote))
      (define (vim-comment-inner-double-quote) (vim-comment-impl select-inner-double-quote))
      (define (vim-comment-around-single-quote) (vim-comment-impl select-around-single-quote))
      (define (vim-comment-inner-single-quote) (vim-comment-impl select-inner-single-quote))


      (provide yank-file-end
               yank-file-start
               vim-delete-file-end
               vim-delete-file-start
               vim-change-file-end
               vim-change-file-start
               vim-indent-file-end
               vim-indent-file-start
               vim-unindent-file-end
               vim-unindent-file-start)

      ;; Yank text objects — around variants (referenced in keymap but never defined)
      (define (yank-around-paragraph) (vim-yank-impl select-around-paragraph))
      (define (yank-around-function) (vim-yank-impl select-around-function))
      (define (yank-around-comment) (vim-yank-impl select-around-comment))
      (define (yank-around-data-structure) (vim-yank-impl select-around-data-structure))
      (define (yank-around-html-tag) (vim-yank-impl select-around-html-tag))
      (define (yank-around-type-definition) (vim-yank-impl select-around-type-definition))
      (define (yank-around-test) (vim-yank-impl select-around-test))

      ;; Yank text objects — inner variants
      (define (yank-inner-paragraph) (vim-yank-impl select-inner-paragraph))
      (define (yank-inner-function) (vim-yank-impl select-inner-function))
      (define (yank-inner-comment) (vim-yank-impl select-inner-comment))
      (define (yank-inner-data-structure) (vim-yank-impl select-inner-data-structure))
      (define (yank-inner-html-tag) (vim-yank-impl select-inner-html-tag))
      (define (yank-inner-type-definition) (vim-yank-impl select-inner-type-definition))
      (define (yank-inner-test) (vim-yank-impl select-inner-test))

      ;; Yank bracket/quote text objects — around
      (define (yank-around-curly) (vim-yank-impl select-around-curly))
      (define (yank-around-paren) (vim-yank-impl select-around-paren))
      (define (yank-around-square) (vim-yank-impl select-around-square))
      (define (yank-around-arrow) (vim-yank-impl select-around-arrow))
      (define (yank-around-double-quote) (vim-yank-impl select-around-double-quote))
      (define (yank-around-single-quote) (vim-yank-impl select-around-single-quote))

      ;; Yank bracket/quote text objects — inner
      (define (yank-inner-curly) (vim-yank-impl select-inner-curly))
      (define (yank-inner-paren) (vim-yank-impl select-inner-paren))
      (define (yank-inner-square) (vim-yank-impl select-inner-square))
      (define (yank-inner-arrow) (vim-yank-impl select-inner-arrow))
      (define (yank-inner-double-quote) (vim-yank-impl select-inner-double-quote))
      (define (yank-inner-single-quote) (vim-yank-impl select-inner-single-quote))

      ;; ye/yE — yank to end of word/WORD (was incorrectly yanking to word start)
      (define (yank-word-end) (vim-yank-impl helix.static.extend_next_word_end))
      (define (yank-long-word-end) (vim-yank-impl helix.static.extend_next_long_word_end))

      ;; Register all fixes — add-global-keybinding merges recursively into
      ;; the existing keymap, so new keys are added and existing leaf values
      ;; for the same key are overridden.
      (define (set-vim-fix-keybindings!)
        (add-global-keybinding
          (keymap
            (normal
              ;; ye/yE — override to yank to word END
              (y (e ":yank-word-end")
                 (E ":yank-long-word-end")
                 ;; File-boundary motions
                 (G ":yank-file-end")
                 (g (g ":yank-file-start"))
                 ;; Bracket/quote text objects for yank — around
                 (a ("{" ":yank-around-curly")
                    ("[" ":yank-around-square")
                    ("(" ":yank-around-paren")
                    ("<" ":yank-around-arrow")
                    ("\"" ":yank-around-double-quote")
                    ("'" ":yank-around-single-quote")
                    ("}" ":yank-around-curly")
                    ("]" ":yank-around-square")
                    (")" ":yank-around-paren")
                    (">" ":yank-around-arrow"))
                 ;; Bracket/quote text objects for yank — inner
                 (i ("{" ":yank-inner-curly")
                    ("[" ":yank-inner-square")
                    ("(" ":yank-inner-paren")
                    ("<" ":yank-inner-arrow")
                    ("\"" ":yank-inner-double-quote")
                    ("'" ":yank-inner-single-quote")
                    ("}" ":yank-inner-curly")
                    ("]" ":yank-inner-square")
                    (")" ":yank-inner-paren")
                    (">" ":yank-inner-arrow")))
            ;; Comment.nvim-compatible gc{motion} operator
            (g
              (c
                (c ":vim-comment-line")
                (w ":vim-comment-word")
                (W ":vim-comment-long-word")
                (b ":vim-comment-prev-word")
                (B ":vim-comment-prev-long-word")
                (e ":vim-comment-word-end")
                (E ":vim-comment-long-word-end")
                (G ":vim-comment-file-end")
                (g (g ":vim-comment-file-start"))
                ($ ":vim-comment-line-end")
                ("0" ":vim-comment-line-start")
                (^ ":vim-comment-first-nonwhitespace")
                (a (w ":vim-comment-around-word")
                   (p ":vim-comment-around-paragraph")
                   (f ":vim-comment-around-function")
                   (c ":vim-comment-around-comment")
                   (e ":vim-comment-around-data-structure")
                   (x ":vim-comment-around-html-tag")
                   (t ":vim-comment-around-type-definition")
                   (T ":vim-comment-around-test")
                   ("{" ":vim-comment-around-curly")
                   ("[" ":vim-comment-around-square")
                   ("(" ":vim-comment-around-paren")
                   ("<" ":vim-comment-around-arrow")
                   ("\"" ":vim-comment-around-double-quote")
                   ("'" ":vim-comment-around-single-quote")
                   ("}" ":vim-comment-around-curly")
                   ("]" ":vim-comment-around-square")
                   (")" ":vim-comment-around-paren")
                   (">" ":vim-comment-around-arrow"))
                (i (w ":vim-comment-inner-word")
                   (p ":vim-comment-inner-paragraph")
                   (f ":vim-comment-inner-function")
                   (c ":vim-comment-inner-comment")
                   (e ":vim-comment-inner-data-structure")
                   (x ":vim-comment-inner-html-tag")
                   (t ":vim-comment-inner-type-definition")
                   (T ":vim-comment-inner-test")
                   ("{" ":vim-comment-inner-curly")
                   ("[" ":vim-comment-inner-square")
                   ("(" ":vim-comment-inner-paren")
                   ("<" ":vim-comment-inner-arrow")
                   ("\"" ":vim-comment-inner-double-quote")
                   ("'" ":vim-comment-inner-single-quote")
                   ("}" ":vim-comment-inner-curly")
                   ("]" ":vim-comment-inner-square")
                   (")" ":vim-comment-inner-paren")
                   (">" ":vim-comment-inner-arrow")))
              (b (c ":vim-comment-block-line")))
            ;; Linewise indentation motions
            (> (G ":vim-indent-file-end")
               (g (g ":vim-indent-file-start")))
            (< (G ":vim-unindent-file-end")
               (g (g ":vim-unindent-file-start")))
            ;; Closing bracket aliases for delete — around
            (d (G ":vim-delete-file-end")
               (g (g ":vim-delete-file-start"))
               (a ("}" ":vim-delete-around-curly")
                  ("]" ":vim-delete-around-square")
                  (")" ":vim-delete-around-paren")
                  (">" ":vim-delete-around-arrow"))
               ;; Closing bracket aliases for delete — inner
               (i ("}" ":vim-delete-inner-curly")
                  ("]" ":vim-delete-inner-square")
                  (")" ":vim-delete-inner-paren")
                  (">" ":vim-delete-inner-arrow")))
            ;; Closing bracket aliases for change — around
            (c (G ":vim-change-file-end")
               (g (g ":vim-change-file-start"))
               (a ("}" ":vim-change-around-curly")
                  ("]" ":vim-change-around-square")
                  (")" ":vim-change-around-paren")
                  (">" ":vim-change-around-arrow"))
               ;; Closing bracket aliases for change — inner
               (i ("}" ":vim-change-inner-curly")
                  ("]" ":vim-change-inner-square")
                  (")" ":vim-change-inner-paren")
                  (">" ":vim-change-inner-arrow")))))))

      (provide yank-around-paragraph
               yank-around-function
               yank-around-comment
               yank-around-data-structure
               yank-around-html-tag
               yank-around-type-definition
               yank-around-test
               yank-inner-paragraph
               yank-inner-function
               yank-inner-comment
               yank-inner-data-structure
               yank-inner-html-tag
               yank-inner-type-definition
               yank-inner-test
               yank-around-curly
               yank-around-paren
               yank-around-square
               yank-around-arrow
               yank-around-double-quote
               yank-around-single-quote
               yank-inner-curly
               yank-inner-paren
               yank-inner-square
               yank-inner-arrow
               yank-inner-double-quote
               yank-inner-single-quote
               yank-word-end
               yank-long-word-end
               vim-comment-block-line
               vim-comment-line
               vim-comment-word
               vim-comment-long-word
               vim-comment-prev-word
               vim-comment-prev-long-word
               vim-comment-word-end
               vim-comment-long-word-end
               vim-comment-line-end
               vim-comment-line-start
               vim-comment-first-nonwhitespace
               vim-comment-file-end
               vim-comment-file-start
               vim-comment-around-word
               vim-comment-inner-word
               vim-comment-around-paragraph
               vim-comment-inner-paragraph
               vim-comment-around-function
               vim-comment-inner-function
               vim-comment-around-comment
               vim-comment-inner-comment
               vim-comment-around-data-structure
               vim-comment-inner-data-structure
               vim-comment-around-html-tag
               vim-comment-inner-html-tag
               vim-comment-around-type-definition
               vim-comment-inner-type-definition
               vim-comment-around-test
               vim-comment-inner-test
               vim-comment-around-curly
               vim-comment-inner-curly
               vim-comment-around-square
               vim-comment-inner-square
               vim-comment-around-paren
               vim-comment-inner-paren
               vim-comment-around-arrow
               vim-comment-inner-arrow
               vim-comment-around-double-quote
               vim-comment-inner-double-quote
               vim-comment-around-single-quote
               vim-comment-inner-single-quote
               set-vim-fix-keybindings!)
    '';
    xdg.configFile."helix/init.scm".text = ''
      (require "plugins/vim-hx/init.scm")
      (set-vim-keybindings!)
      (require "paragraph-delete.scm")
      (set-paragraph-delete-keybindings!)
      (require "vim-fixes.scm")
      (set-vim-fix-keybindings!)
      (require "plugins/wakatime/wakatime.scm")
      (require "forest/forest.scm")
      ;; forest.hx recurses into every directory via read-dir, following symlinks.
      ;; Nix repos have `result` -> /nix/store/.../<full system closure> and
      ;; `.devenv/{profile,bash,run}` -> /nix/store/... symlinks; walking those
      ;; traverses the entire NixOS closure and hangs the editor on space+e.
      ;; forest-configure! REPLACES the ignore set, so list every default too.
      (forest-configure! 'left #:ignore (list ".git" "target" ".direnv" ".devenv" "node_modules" "__pycache__" ".hg" "result"))
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
  };
}
