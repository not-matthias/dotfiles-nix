{
  config,
  flakes,
  pkgs,
  unstable,
  options,
  lib,
  ...
}: let
  palettes = import ../../../system/desktop/palettes.nix;
  helixTheme = palette:
    pkgs.writeText "helix-runtime-theme.toml" ''
      "ui.background" = { fg = "base05", bg = "base00" }
      "ui.text" = "base05"
      "ui.text.focus" = { fg = "base05", modifiers = ["bold"] }
      "ui.cursor" = { fg = "base00", bg = "base05" }
      "ui.cursor.primary" = { fg = "base00", bg = "base05" }
      "ui.selection" = { bg = "base02" }
      "ui.selection.primary" = { bg = "base02" }
      "ui.linenr" = "base03"
      "ui.linenr.selected" = { fg = "base04", modifiers = ["bold"] }
      "ui.statusline" = { fg = "base05", bg = "base01" }
      "ui.statusline.inactive" = { fg = "base03", bg = "base00" }
      "ui.popup" = { fg = "base05", bg = "base01" }
      "ui.menu" = { fg = "base05", bg = "base01" }
      "ui.menu.selected" = { fg = "base00", bg = "base0D" }
      "ui.window" = { fg = "base03", bg = "base00" }
      "ui.virtual" = "base03"
      "ui.cursorline.primary" = { bg = "base01" }
      "ui.highlight" = { bg = "base02" }
      error = "base08"
      warning = "base0A"
      info = "base0D"
      hint = "base0C"
      comment = { fg = "base03", modifiers = ["italic"] }
      constant = "base09"
      string = "base0B"
      variable = "base05"
      "variable.builtin" = "base0C"
      type = "base0A"
      constructor = "base0A"
      function = "base0D"
      keyword = "base0E"
      operator = "base0C"
      namespace = "base0A"
      tag = "base08"
      attribute = "base0A"
      punctuation = "base05"
      "markup.heading" = { fg = "base0D", modifiers = ["bold"] }
      "markup.list" = "base08"
      "markup.bold" = { modifiers = ["bold"] }
      "markup.italic" = { modifiers = ["italic"] }
      "markup.link.url" = { fg = "base0C", modifiers = ["underlined"] }
      "markup.link.text" = "base08"
      "markup.raw" = "base0B"
      "diff.plus" = "base0B"
      "diff.minus" = "base08"
      "diff.delta" = "base0A"
      [palette]
      base00 = "#${palette.base00}"
      base01 = "#${palette.base01}"
      base02 = "#${palette.base02}"
      base03 = "#${palette.base03}"
      base04 = "#${palette.base04}"
      base05 = "#${palette.base05}"
      base06 = "#${palette.base06}"
      base07 = "#${palette.base07}"
      base08 = "#${palette.base08}"
      base09 = "#${palette.base09}"
      base0A = "#${palette.base0A}"
      base0B = "#${palette.base0B}"
      base0C = "#${palette.base0C}"
      base0D = "#${palette.base0D}"
      base0E = "#${palette.base0E}"
      base0F = "#${palette.base0F}"

    '';
  initialMode = config.stylix.polarity or "light";
  steelPtySource = pkgs.applyPatches {
    name = "steel-pty-source";
    src = flakes.steel-pty;
    patches = [./steel-pty-bottom-panel.patch];
  };
  steelPty = pkgs.rustPlatform.buildRustPackage rec {
    pname = "steel-pty";
    version = "0.1.0-unstable-2026-08-28";
    src = steelPtySource;
    cargoHash = "sha256-vUlSStpLgcOgpCgqWlcNFgDxemIoP0Hak3BG+iR6agc=";
    postPatch = ''
      ln -s termwiz-0.24.0 "$cargoDepsCopy/source-git-0/termwiz"
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTarget}/release/libsteel_pty.so $out/lib/libsteel_pty.so
      runHook postInstall
    '';
  };
in {
  config =
    (lib.optionalAttrs (options ? stylix) {
      stylix.targets.helix.enable = false;
    })
    // {
      programs.fish.shellAbbrs.h = "hx .";
      programs.fish.functions.helix = ''
        hx $argv
      '';
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
                patch -p1 < ${./configurable-dot-repeat.patch}
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
              formatter.command = "alejandra";
            }
          ];
          language-server = {
            "harper-ls" = {
              command = "harper-ls";
              args = ["--stdio"];
            };
            # Nix's clang is a wrapper script that injects the glibc header
            # paths; clangd uses its own built-in driver logic, so without
            # querying the real driver it finds no system headers at all.
            "clangd" = {
              command = "clangd";
              args = ["--query-driver=/nix/store/*/bin/*"];
            };
            # The rustup package's `rust-analyzer` proxy wins the profile PATH
            # merge; without the component installed it exits at startup.
            "rust-analyzer".command = lib.getExe pkgs.rust-analyzer;
            "nil".config.nil.nix.flake.autoArchive = true;
            # Request timeout in seconds (default 20). A server that stops
            # answering blocks `:w` for this long, since writes await the
            # formatting response before the save future is queued.
            "yaml-language-server".timeout = 3;
            # Without an explicit option set, nixd evaluates <nixpkgs/nixos>
            # and knows neither this flake's modules nor Home Manager options.
            "nixd".config.nixd = let
              flake = ''(builtins.getFlake "${config.home.homeDirectory}/projects/dotfiles-nix")'';
              hostOptions = host: "${flake}.nixosConfigurations.${host}.options";
            in {
              nixpkgs.expr = "import ${flake}.inputs.nixpkgs {}";
              options = {
                nixos.expr = hostOptions "pc";
                nixos-framework.expr = hostOptions "framework";
                # `type.getSubOptions` only sees the shared submodule; the
                # evaluated per-user tree includes the host's own HM modules.
                home-manager.expr = "${hostOptions "pc"}.home-manager.users.valueMeta.attrs.${config.home.username}.configuration.options";
              };
            };
          };
        };
        settings = {
          theme = {
            dark = "desktop-dark";
            light = "desktop-light";
            fallback = "desktop-${initialMode}";
          };
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
            space.H = ":toggle-term";
            space.e = ":forest-open";
            space.t = ":theme-picker-open";
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
              ":insert-output glow --pager --width 120 --style=$(desktop-theme get) '%{buffer_name}' </dev/tty >/dev/tty 2>&1"
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
            # `Q<edit>Q` records a macro; `.` replays it.
            "." = "replay_macro";
            "C-/" = "toggle_line_comments";
            "C-p" = "file_picker";
            "C-b" = "goto_definition";
            "C-h" = ":hide-terminal";
            "C-j" = ":toggle-term";
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
            space.x = ":buffer-close";
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
      xdg.configFile = {
        "helix/themes/desktop-light.toml".source = helixTheme palettes.light;
        "helix/themes/desktop-dark.toml".source = helixTheme palettes.dark;
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
      xdg.configFile."helix/microscope".source = pkgs.applyPatches {
        name = "microscope-hx-patched";
        src = flakes.microscopehx;
        patches = [./microscope-live-preview.patch];
      };
      xdg.dataFile."steel/cogs/helix-file-watcher".source = "${pkgs.helix-file-watcher}/share/steel/cogs/helix-file-watcher";
      xdg.dataFile."steel/native/libhelix_file_watcher.so".source = "${pkgs.helix-file-watcher}/lib/libhelix_file_watcher.so";
      xdg.configFile."helix/vim-hx-additions".source = ./vim-hx-additions;
      xdg.dataFile."steel/cogs/steel-pty".source = steelPtySource;
      xdg.dataFile."steel/native/libsteel_pty.so".source = "${steelPty}/lib/libsteel_pty.so";
      xdg.configFile."helix/theme-picker".source = ./theme-picker;
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
