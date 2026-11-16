{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.tern;
  spacesRoot = ../../../pkgs/tern-plugins/spaces;
  # Tests and benchmarks stay out of the linked plugin, and editing them does not relink it.
  spaces = lib.fileset.toSource {
    root = spacesRoot;
    fileset = lib.fileset.unions [(spacesRoot + "/plugin.toml") (spacesRoot + "/src")];
  };

  settingsFile = pkgs.writeText "tern-settings.json" (builtins.toJSON cfg.settings);
in {
  options.programs.tern = {
    enable = lib.mkEnableOption "Tern terminal with persistent sessions";

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = ''
        Settings merged into ~/.config/tern/settings.json on activation.
        Tern writes that file itself (window sizes, recents), so it is merged
        rather than symlinked: declared keys win, runtime-only keys survive.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.tern];

    programs.tern.settings = {
      theme = "System";
      theme_light = "light-prism";
      cursor.trail = "warp";
      link_target = "Browser";
      font_size = 15;
      system_title_bar = true;
      tmux_status = false;
      material = "Solid";
      opacity = 100;
      plugins_disabled = ["tidal"];
      surface_diffs = "Split";
      surface_fold = true;
      context_bar = false;
      keep_composer_open = true;
      composer_text = "Markdown";
      surface_chat = "Console";
      shell = "/etc/profiles/per-user/${config.home.username}/bin/fish";
      prompt_style = "starship";
      sync_to_display = false;
      files.auto_save.after_delay = 1000;
      git.path_tree = true;
      keymap = "tmux";
      keybinds = {
        "ctrl+alt+[" = "previous_tab";
        "ctrl+alt+]" = "next_tab";
        "ctrl+alt+b" = "toggle_sidebar";
        "ctrl+alt+c" = "new_tab";
        "ctrl+alt+d" = "split_right";
        "ctrl+alt+h" = "focus_pane:left";
        "ctrl+alt+j" = "focus_pane:down";
        "ctrl+alt+k" = "focus_pane:up";
        "ctrl+alt+l" = "focus_pane:right";
        "ctrl+alt+p" = "plugin.spaces.open_profile";
        "ctrl+alt+shift+d" = "split_down";
        "ctrl+alt+tab" = "plugin.multiplexer.last_pane";
        "ctrl+alt+z" = "zoom";
        "ctrl+b>," = "plugin.multiplexer.previous_agent";
        "ctrl+b>." = "plugin.multiplexer.next_agent";
        "ctrl+b>1" = "goto_tab:1";
        "ctrl+b>2" = "goto_tab:2";
        "ctrl+b>3" = "goto_tab:3";
        "ctrl+b>4" = "goto_tab:4";
        "ctrl+b>5" = "goto_tab:5";
        "ctrl+b>6" = "goto_tab:6";
        "ctrl+b>7" = "goto_tab:7";
        "ctrl+b>8" = "goto_tab:8";
        "ctrl+b>9" = "goto_tab:9";
        "ctrl+b>b" = "toggle_sidebar";
        "ctrl+b>c" = "new_tab";
        "ctrl+b>ctrl+b" = "plugin.multiplexer.send_prefix";
        "ctrl+b>ctrl+x" = "close_tab";
        "ctrl+b>h" = "focus_pane:left";
        "ctrl+b>j" = "focus_pane:down";
        "ctrl+b>k" = "focus_pane:up";
        "ctrl+b>l" = "focus_pane:right";
        "ctrl+b>minus" = "split_down";
        "ctrl+b>n" = "next_tab";
        "ctrl+b>p" = "previous_tab";
        "ctrl+b>shift+1" = "plugin.multiplexer.agent_1";
        "ctrl+b>shift+2" = "plugin.multiplexer.agent_2";
        "ctrl+b>shift+3" = "plugin.multiplexer.agent_3";
        "ctrl+b>shift+4" = "plugin.multiplexer.agent_4";
        "ctrl+b>shift+5" = "plugin.multiplexer.agent_5";
        "ctrl+b>shift+6" = "plugin.multiplexer.agent_6";
        "ctrl+b>shift+7" = "plugin.multiplexer.agent_7";
        "ctrl+b>shift+8" = "plugin.multiplexer.agent_8";
        "ctrl+b>shift+9" = "plugin.multiplexer.agent_9";
        "ctrl+b>shift+n" = "plugin.spaces.new_space";
        "ctrl+b>shift+r" = "plugin.multiplexer.label_agent";
        "ctrl+b>v" = "split_right";
        "ctrl+b>w>1" = "plugin.spaces.space_1";
        "ctrl+b>w>2" = "plugin.spaces.space_2";
        "ctrl+b>w>3" = "plugin.spaces.space_3";
        "ctrl+b>w>4" = "plugin.spaces.space_4";
        "ctrl+b>w>5" = "plugin.spaces.space_5";
        "ctrl+b>w>6" = "plugin.spaces.space_6";
        "ctrl+b>w>7" = "plugin.spaces.space_7";
        "ctrl+b>w>8" = "plugin.spaces.space_8";
        "ctrl+b>w>9" = "plugin.spaces.space_9";
        "ctrl+b>x" = "close_tab";
        "ctrl+b>z" = "zoom";
        "ctrl+shift+tab" = "previous_tab";
        "ctrl+shift+w" = "close_pane";
        "ctrl+tab" = "next_tab";
      };
    };

    home.activation.ternMultiplexer = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${lib.getExe pkgs.tern} plugin link ${../../../pkgs/tern-plugins/multiplexer}
    '';

    home.activation.ternSpaces = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${lib.getExe pkgs.tern} plugin link ${spaces}
    '';

    home.activation.ternSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      target="$HOME/.config/tern/settings.json"
      $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
      if [ -f "$target" ]; then
        $DRY_RUN_CMD ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$target" ${settingsFile} > "$target.tmp"
      else
        $DRY_RUN_CMD cp ${settingsFile} "$target.tmp"
      fi
      $DRY_RUN_CMD mv -f "$target.tmp" "$target"
    '';

    xdg.desktopEntries.tern = {
      name = "Tern";
      comment = "Native terminal with persistent sessions";
      exec = lib.getExe pkgs.tern;
      terminal = false;
      categories = ["System" "TerminalEmulator"];
    };
  };
}
