{
  config,
  flakes,
  pkgs,
  unstable,
  lib,
  options,
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
  config =
    (lib.optionalAttrs (options ? stylix) {
      stylix.targets.helix.enable = true;
    })
    // {
      programs.fish.shellAbbrs.h = "hx .";
      programs.helix = {
        enable = true;
        # nixpkgs' steelix expression replaces `patches` on the unwrapped derivation,
        # so extra source patches are applied through `postPatch`, which it leaves alone.
        package = unstable.steelix.override {
          helix-unwrapped = unstable.helix-unwrapped.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                patch -p1 < ${./multi-char-auto-pairs.patch}
              '';
          });
        };
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
              formatter = {
                command = "prettier";
                args = ["--parser" "markdown"];
              };
              auto-pairs = {
                "(" = ")";
                "{" = "}";
                "\"" = "\"";
                "`" = "`";
                "```" = "```";
              };
            }
            {
              name = "nix";
              auto-format = false;
              formatter = {
                command = "alejandra";
              };
            }
          ];
          language-server = {
            "harper-ls" = {
              command = "harper-ls";
              args = ["--stdio"];
            };
            "nil" = {
              config.nil.nix.flake.autoArchive = true;
            };
          };
        };
        settings = {
          editor = {
            clipboard-provider = "termcode";
            bufferline = "multiple";
            cursorline = true;
            line-number = "relative";
            text-width = 120;
            rulers = [120];
            popup-border = "all";
            trim-trailing-whitespace = true;
            insert-final-newline = true;
            end-of-line-diagnostics = "hint";
            rainbow-brackets = true;
            soft-wrap = {
              enable = true;
              wrap-at-text-width = true;
            };

            insecure = true;

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

            auto-save = {
              focus-lost = true;
              after-delay = {
                enable = true;
                timeout = 3000;
              };
            };
          };

          keys.normal = {
            space.f = "file_picker";
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
            # Helix has no repeat-last-change command, so `.` aliases the macro
            # replay that `q` already runs: `Q<edit>Q` records, `.` repeats it.
            # `A-.` stays repeat_last_motion (last f/t/search).
            "." = "replay_macro";
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
              K = "normal_mode";
            };
            J = {
              k = "normal_mode";
              K = "normal_mode";
            };
          };
        };
      };

      # Steel plugins (loaded via init.scm on steelix startup)
      xdg.configFile."helix/plugins/vim-hx".source = flakes.vimhx;
      xdg.configFile."helix/plugins/wakatime".source = flakes.wakatimehx;
      xdg.configFile."helix/forest".source = pkgs.runCommand "forest-hx-patched" {} ''
        cp -r ${flakes.foresthx} $out
        chmod -R u+w $out
        substituteInPlace $out/forest.scm \
          --replace-fail '(define *forest-width* 32) ;' '(define *forest-width* 48) ;' \
          --replace-fail '(define *forest-max-width* 60)' '(define *forest-max-width* 500)'
      '';
      xdg.configFile."helix/notify".source = flakes.notifyhx;
      xdg.configFile."helix/glyph".source = flakes.glyphhx;
      xdg.configFile."helix/vim-hx-additions".source = ./vim-hx-additions;
      xdg.configFile."helix/init.scm".source = ./init.scm;

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
