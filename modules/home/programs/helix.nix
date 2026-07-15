{
  flakes,
  pkgs,
  ...
}: {
  stylix.targets.helix.enable = false;

  programs.helix = {
    enable = true;
    package = flakes.evil-helix.packages.${pkgs.stdenv.hostPlatform.system}.helix;
    extraPackages = with pkgs; [
      marksman
      nixd
      rust-analyzer
      taplo
    ];
    languages = {
      language = [
        {
          name = "rust";
          auto-format = true;
        }
        {
          name = "nix";
          auto-format = true;
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
        true-color = true;
        color-modes = true;
        popup-border = "all";
        trim-trailing-whitespace = true;
        insert-final-newline = true;
        end-of-line-diagnostics = "hint";

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides = {
          render = true;
          character = "╎";
        };

        lsp = {
          display-messages = true;
          auto-signature-help = false;
          display-inlay-hints = true;
        };

        statusline = {
          left = ["mode" "spinner" "version-control" "file-name"];
          right = ["diagnostics" "selections" "position" "file-encoding" "file-line-ending"];
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
        space.w = ":w";
        space.q = ":q";
        esc = ["collapse_selection" "keep_primary_selection"];
        "A-," = "goto_previous_buffer";
        "A-." = "goto_next_buffer";
        "A-w" = ":buffer-close";
      };
    };
  };
}
