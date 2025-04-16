{
  unstable,
  pkgs,
  ...
}: {
  programs.helix = {
    enable = false;
    package = unstable.helix;
    extraPackages = with pkgs; [
      marksman
    ];
    languages = [
      {
        name = "rust";
        auto-format = true;
      }
      {
        name = "nix";
        auto-format = true;
      }
    ];
    settings = {
      theme = "ayu_dark";
      editor = {
        cursor-shape.insert = "bar";
        line-number = "relative";
        lsp.display-messages = true;
      };
      keys.normal = {
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
        esc = ["collapse_selection" "keep_primary_selection"];
      };
    };
  };
}
