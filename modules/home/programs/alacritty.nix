{unstable, ...}: {
  programs.alacritty = {
    package = unstable.alacritty;
    settings = {
      keyboard.bindings = [
        {
          key = "Return";
          mods = "Shift";
          chars = "\n";
        }
        {
          key = "Back";
          mods = "Control";
          chars = "\\u0017";
        }
        {
          key = "Delete";
          mods = "Control";
          chars = "\\u001b[3;5~";
        }
        {
          key = "Back";
          mods = "Alt";
          chars = "\\u001b\\u007f";
        }
      ];
      # Default is ",│`|:\"' ()[]{}<>\t" — removed ":" so double-click selects full URLs
      selection.semantic_escape_chars = ",│`|\"' ()[]{}<>\t";
      hints.enabled = [
        {
          regex = "(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https?://|news:|file:|git:|ssh:|ftp:)[^\\u0000-\\u001F\\u007F-\\u009F<>\"\\\\s{-}\\\\^⟨⟩`\\\\|]+";
          hyperlinks = true;
          post_processing = true;
          persist = false;
          command = "xdg-open";
          binding = {
            key = "O";
            mods = "Control|Shift";
          };
          mouse = {enabled = false;};
        }
      ];
    };
  };
}
