{
  config,
  pkgs,
  ...
}: let
  tmuxConf = builtins.readFile ./default.conf;
in {
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    extraConfig = tmuxConf;
    escapeTime = 0;
    keyMode = "vi";
    plugins = with plugins; [
      cpu
    ];
    shortcut = "a";
    terminal = "screen-256color";
  };
}
