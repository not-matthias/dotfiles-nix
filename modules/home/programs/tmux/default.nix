{pkgs, ...}: let
  plugins = pkgs.tmuxPlugins;
  tmuxConf = builtins.readFile ./default.conf;
in {
  programs.tmux = {
    aggressiveResize = true;
    baseIndex = 1;
    extraConfig = tmuxConf;
    escapeTime = 0;
    #    keyMode = "vi";
    plugins = with plugins; [
      cpu
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-boot 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
  };
}
