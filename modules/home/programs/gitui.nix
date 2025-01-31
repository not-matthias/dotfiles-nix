# References:
# - https://github.com/linuxmobile/kaku/blob/9d409fcd7f4a54014876fbd5f5139e7bb2bdc0f1/home/terminal/software/gitui.nix#L4
{
  programs.gitui = {
    # enable = true;
    keyConfig = ''
      (
        open_help: Some(( code: ?, modifiers: "")),

        move_left: Some(( code: Char('h'), modifiers: "",)),
        move_right: Some(( code: Char('l'), modifiers: "",)),
        move_up: Some(( code: Char('k'), modifiers: "",)),
        move_down: Some(( code: Char('j'), modifiers: "",)),
      )
    '';
  };
}
