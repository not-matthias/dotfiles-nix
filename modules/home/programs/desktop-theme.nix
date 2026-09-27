{
  config,
  lib,
  pkgs,
  ...
}: let
  palettes = import ../../system/desktop/palettes.nix;
  initialMode = config.stylix.polarity or "light";
  paletteColors = mode: config.stylix.base16.mkSchemeAttrs palettes.${mode};
  ghosttyTheme = name: palette:
    pkgs.writeText name ''
      background = #${palette.base00}
      foreground = #${palette.base05}
      cursor-color = #${palette.base05}
      selection-background = #${palette.base02}
      selection-foreground = #${palette.base05}
      palette = 0=#${palette.base00}
      palette = 1=#${palette.base08}
      palette = 2=#${palette.base0B}
      palette = 3=#${palette.base0A}
      palette = 4=#${palette.base0D}
      palette = 5=#${palette.base0E}
      palette = 6=#${palette.base0C}
      palette = 7=#${palette.base05}
      palette = 8=#${palette.base03}
      palette = 9=#${palette.base08}
      palette = 10=#${palette.base0B}
      palette = 11=#${palette.base0A}
      palette = 12=#${palette.base0D}
      palette = 13=#${palette.base0E}
      palette = 14=#${palette.base0C}
      palette = 15=#${palette.base07}
    '';
  lightTheme = ghosttyTheme "catppuccin-latte-red-ghostty" palettes.light;
  darkTheme = ghosttyTheme "catppuccin-mocha-red-ghostty" palettes.dark;
  dunstEnabled = config.services.dunst.enable;
  dunstConfig = mode: let
    colors = (paletteColors mode).withHashtag;
    opacity = config.stylix.opacity.popups;
    alpha = lib.toHexString (((builtins.floor (opacity * 100 + 0.5)) * 255) / 100);
  in
    pkgs.writeText "dunst-${mode}.conf" ''
      [global]
      separator_color="${colors.base02}"

      [urgency_low]
      background="${colors.base01}${alpha}"
      foreground="${colors.base05}"
      frame_color="${colors.base03}"
      highlight="${colors.base03}"

      [urgency_normal]
      background="${colors.base01}${alpha}"
      foreground="${colors.base05}"
      frame_color="${colors.base0D}"
      highlight="${colors.base0D}"

      [urgency_critical]
      background="${colors.base01}${alpha}"
      foreground="${colors.base05}"
      frame_color="${colors.base08}"
      highlight="${colors.base08}"
    '';
  swaylockEnabled = config.programs.swaylock.enable;
  swaylockSource =
    if swaylockEnabled
    then config.home.file."${config.home.homeDirectory}/.config/swaylock/config".source
    else null;
  swaylockConfig = mode:
    if !swaylockEnabled
    then null
    else let
      colors = paletteColors mode;
      source = builtins.readFile swaylockSource;
      colorSettings = {
        color = "000000";
        inside-caps-lock-color = colors.base00-hex;
        inside-clear-color = colors.base00-hex;
        inside-color = colors.base00-hex;
        inside-ver-color = colors.base00-hex;
        inside-wrong-color = colors.base00-hex;
        key-hl-color = colors.base0B-hex;
        layout-bg-color = colors.base00-hex;
        layout-border-color = colors.base01-hex;
        layout-text-color = colors.base05-hex;
        ring-caps-lock-color = colors.base01-hex;
        ring-clear-color = colors.base08-hex;
        ring-color = colors.base01-hex;
        ring-ver-color = colors.base0B-hex;
        ring-wrong-color = colors.base08-hex;
        text-caps-lock-color = colors.base05-hex;
        text-clear-color = colors.base05-hex;
        text-color = colors.base05-hex;
        text-ver-color = colors.base05-hex;
        text-wrong-color = colors.base05-hex;
      };
      oldValues = map (name: "${name}=${toString config.programs.swaylock.settings.${name}}") (builtins.attrNames colorSettings);
      newValues = map (name: "${name}=${colorSettings.${name}}") (builtins.attrNames colorSettings);
    in
      pkgs.writeText "swaylock-${mode}.config" (builtins.replaceStrings oldValues newValues source);
  qtEnabled = config.qt.enable;
  qtSource = suffix:
    config.home.file."${config.home.homeDirectory}/.config/${suffix}".source;
  qtConfig = mode: suffix: let
    source = builtins.readFile (qtSource "${suffix}/${suffix}.conf");
    iconFrom =
      if initialMode == "dark"
      then "Papirus-Dark"
      else "Papirus";
    iconTo =
      if mode == "dark"
      then "Papirus-Dark"
      else "Papirus";
  in
    pkgs.writeText "${suffix}-${mode}.conf"
    (builtins.replaceStrings ["custom_palette=true" iconFrom] ["custom_palette=false" iconTo] source);
  kvantumSource = config.home.file."${config.home.homeDirectory}/.config/Kvantum/kvantum.kvconfig".source;
  kvantumConfig = mode: let
    variant =
      if mode == "light"
      then "latte"
      else "mocha";
  in
    pkgs.writeText "kvantum-${mode}.kvconfig"
    (builtins.replaceStrings
      ["theme=Base16Kvantum"]
      ["theme=catppuccin-${variant}-red"]
      (builtins.readFile kvantumSource));
  fishEnabled = config.programs.fish.enable;
  btopEnabled = config.programs.btop.enable;
  vicinaeEnabled = config.programs.vicinae.enable;
  vicinaePackage = config.programs.vicinae.package;
  vicinaeTheme = mode: let
    colors = (paletteColors mode).withHashtag;
  in {
    meta = {
      version = 1;
      name = "Catppuccin ${
        if mode == "light"
        then "Latte"
        else "Mocha"
      } Red";
      description = "Desktop ${mode} theme";
      variant = mode;
      inherits = "vicinae-${mode}";
    };
    colors.core = {
      background = colors.base00;
      foreground = colors.base05;
      secondary_background = colors.base01;
      border = colors.base02;
      accent = colors.base0D;
    };
    colors.accents = {
      blue = colors.base0D;
      green = colors.base0B;
      magenta = colors.base0E;
      orange = colors.base09;
      purple = colors.base0E;
      red = colors.base08;
      yellow = colors.base0A;
      cyan = colors.base0C;
    };
  };
  modeDir = mode:
    pkgs.runCommandLocal "desktop-theme-${mode}-configs" {} ''
      mkdir -p "$out"/{dunst/dunstrc.d,swaylock,qt5ct,qt6ct,Kvantum,btop}
      ${lib.optionalString dunstEnabled ''ln -s ${dunstConfig mode} "$out/dunst/dunstrc.d/99-desktop-theme.conf"''}
      ${lib.optionalString swaylockEnabled ''ln -s ${swaylockConfig mode} "$out/swaylock/config"''}
      ${lib.optionalString qtEnabled ''
        ln -s ${qtConfig mode "qt5ct"} "$out/qt5ct/qt5ct.conf"
        ln -s ${qtConfig mode "qt6ct"} "$out/qt6ct/qt6ct.conf"
        ln -s ${kvantumConfig mode} "$out/Kvantum/kvantum.kvconfig"
      ''}
      ${lib.optionalString btopEnabled ''
        ln -s ${config.programs.btop.package}/share/btop/themes/adwaita${lib.optionalString (mode == "dark") "-dark"}.theme "$out/btop/theme.theme"
      ''}
    '';
  lightDir = modeDir "light";
  darkDir = modeDir "dark";
  desktopTheme = pkgs.writeShellApplication {
    name = "desktop-theme";
    runtimeInputs =
      [pkgs.coreutils pkgs.glib.bin pkgs.gsettings-desktop-schemas pkgs.util-linux]
      ++ lib.optionals (dunstEnabled || vicinaeEnabled) [pkgs.systemd]
      ++ lib.optionals dunstEnabled [config.services.dunst.package]
      ++ lib.optionals fishEnabled [config.programs.fish.package]
      ++ lib.optionals vicinaeEnabled [vicinaePackage];
    text = ''
      umask 077
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/desktop-theme"
      state_file="$state_dir/mode"
      default_mode=${lib.escapeShellArg initialMode}
      export GSETTINGS_SCHEMA_DIR=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas
      mkdir -p "$state_dir"
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"

      link_config() {
        target_dir=$(dirname "$2")
        mkdir -p "$target_dir"
        tmp=$(mktemp "$target_dir/.desktop-theme.XXXXXX")
        ln -sfn "$1" "$tmp"
        mv -Tf "$tmp" "$2"
      }

      ensure_config_link() {
        if [ "$(readlink "$2")" != "$1" ]; then
          link_config "$1" "$2"
        fi
      }

      get_mode() {
        if [ -f "$state_file" ]; then
          cat "$state_file"
        else
          printf '%s\n' "$default_mode"
        fi
      }

      prepare_mode() {
        case "$1" in
          light) mode_dir=${lightDir} ;;
          dark) mode_dir=${darkDir} ;;
          *) printf 'invalid theme mode: %s\n' "$1" >&2; exit 2 ;;
        esac
        ${lib.optionalString dunstEnabled ''ensure_config_link "$config_home/desktop-theme/current/dunst/dunstrc.d/99-desktop-theme.conf" "$config_home/dunst/dunstrc.d/99-desktop-theme.conf"''}
        ${lib.optionalString swaylockEnabled ''ensure_config_link "$config_home/desktop-theme/current/swaylock/config" "$config_home/swaylock/config"''}
        ${lib.optionalString qtEnabled ''
        ensure_config_link "$config_home/desktop-theme/current/qt5ct/qt5ct.conf" "$config_home/qt5ct/qt5ct.conf"
        ensure_config_link "$config_home/desktop-theme/current/qt6ct/qt6ct.conf" "$config_home/qt6ct/qt6ct.conf"
        ensure_config_link "$config_home/desktop-theme/current/Kvantum/kvantum.kvconfig" "$config_home/Kvantum/kvantum.kvconfig"
      ''}
        ${lib.optionalString btopEnabled ''ensure_config_link "$config_home/desktop-theme/current/btop/theme.theme" "$config_home/btop/themes/desktop-current.theme"''}
        link_config "$mode_dir" "$config_home/desktop-theme/current"
      }

      apply_mode() {
        case "$1" in
          light) variant=latte; icon_theme=Papirus ;;
          dark) variant=mocha; icon_theme=Papirus-Dark ;;
          *) printf 'invalid theme mode: %s\n' "$1" >&2; exit 2 ;;
        esac
        prepare_mode "$1"
        ${lib.optionalString fishEnabled ''
        # Clear persisted colors from the retired Base16 Fish hook so shells
        # use Ghostty's live ANSI palette instead.
        # shellcheck disable=SC2016
        fish -c '
          if set -q base16_theme; and test "$base16_theme" = untitled
            for name in \
              base16_theme \
              fish_color_autosuggestion fish_color_cancel fish_color_command fish_color_comment fish_color_cwd fish_color_cwd_root fish_color_end fish_color_error fish_color_escape fish_color_history_current fish_color_host fish_color_match fish_color_normal fish_color_operator fish_color_param fish_color_quote fish_color_redirection fish_color_search_match fish_color_selection fish_color_status fish_color_user fish_color_valid_path fish_pager_color_completion fish_pager_color_description fish_pager_color_prefix fish_pager_color_progress
              if set -qU $name
                set -eU $name
              end
            end
          end
        '
      ''}
        ${lib.optionalString dunstEnabled ''
        if systemctl --user is-active --quiet dunst.service; then
          dunstctl reload
        fi
      ''}
        ${lib.optionalString vicinaeEnabled ''
        if systemctl --user is-active --quiet vicinae.service 2>/dev/null; then
          if ! vicinae theme set "desktop-$1"; then
            printf 'warning: failed to update Vicinae theme to desktop-%s\n' "$1" >&2
          fi
        fi
      ''}
        gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-$variant-red-compact"
        gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-$1"
      }

      save_mode() {
        tmp=$(mktemp "$state_dir/.mode.XXXXXX")
        trap 'if [ -e "$tmp" ]; then unlink "$tmp"; fi' EXIT
        printf '%s\n' "$mode" > "$tmp"
        chmod 600 "$tmp"
        mv -f "$tmp" "$state_file"
      }

      case "''${1:-}" in
        get)
          if [ "$#" -eq 2 ] && [ "$2" = --json ]; then
            printf '{"mode":"%s"}\n' "$(get_mode)"
          elif [ "$#" -eq 1 ]; then
            get_mode
          else
            printf 'usage: desktop-theme get [--json]\n' >&2; exit 2
          fi
          ;;
        set)
          [ "$#" -eq 2 ] || { printf 'usage: desktop-theme set <light|dark>\n' >&2; exit 2; }
          case "$2" in light|dark) mode=$2 ;; *) printf 'invalid theme mode: %s\n' "$2" >&2; exit 2 ;; esac
          exec 9>"$state_dir/lock"
          flock 9
          apply_mode "$mode"
          save_mode
          ;;
        toggle)
          [ "$#" -eq 1 ] || { printf 'usage: desktop-theme toggle\n' >&2; exit 2; }
          exec 9>"$state_dir/lock"
          flock 9
          current=$(get_mode)
          if [ "$current" = light ]; then mode=dark; else mode=light; fi
          apply_mode "$mode"
          save_mode
          ;;
        setup)
          [ "$#" -eq 1 ] || { printf 'usage: desktop-theme setup\n' >&2; exit 2; }
          exec 9>"$state_dir/lock"
          flock 9
          prepare_mode "$(get_mode)"
          ;;
        restore)
          [ "$#" -eq 1 ] || { printf 'usage: desktop-theme restore\n' >&2; exit 2; }
          exec 9>"$state_dir/lock"
          flock 9
          apply_mode "$(get_mode)"
          ;;
        *) printf 'usage: desktop-theme {get [--json]|set <light|dark>|toggle}\n' >&2; exit 2 ;;
      esac
    '';
  };
in {
  stylix.targets.gnome.enable = false;
  stylix.targets.gtk.enable = false;
  stylix.targets.bat.enable = false;
  stylix.targets.btop.enable = false;
  stylix.targets.fish.enable = false;
  stylix.targets.starship.enable = false;
  stylix.targets.gitui.enable = false;
  stylix.targets.lazygit.enable = false;
  stylix.targets.zellij.enable = false;
  stylix.targets.ghostty.enable = false;
  stylix.targets.nixvim.enable = false;
  programs.vicinae.package = lib.mkIf vicinaeEnabled (lib.mkDefault pkgs.vicinae);
  programs.vicinae.themes = lib.mkIf vicinaeEnabled {
    desktop-light = vicinaeTheme "light";
    desktop-dark = vicinaeTheme "dark";
  };
  home.file."${config.home.homeDirectory}/.config/swaylock/config".enable =
    lib.mkIf swaylockEnabled (lib.mkForce false);
  home.file."${config.home.homeDirectory}/.config/qt5ct/qt5ct.conf".enable =
    lib.mkIf qtEnabled (lib.mkForce false);
  home.file."${config.home.homeDirectory}/.config/qt6ct/qt6ct.conf".enable =
    lib.mkIf qtEnabled (lib.mkForce false);
  home.file."${config.home.homeDirectory}/.config/Kvantum/kvantum.kvconfig".enable =
    lib.mkIf qtEnabled (lib.mkForce false);
  xdg.configFile = {
    "ghostty/themes/Catppuccin Latte Red".source = lightTheme;
    "ghostty/themes/Catppuccin Mocha Red".source = darkTheme;
  };
  home.activation.migrateDesktopThemeConfigs = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    for name in dunst/dunstrc bat/config btop/btop.conf; do
      if [ "$(${pkgs.coreutils}/bin/readlink "$config_home/$name")" = "$config_home/desktop-theme/current/$name" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/unlink "$config_home/$name"
      fi
    done
  '';
  home.activation.restoreDesktopTheme = lib.hm.dag.entryAfter ["linkGeneration"] ''
    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet graphical-session.target; then
      $DRY_RUN_CMD ${desktopTheme}/bin/desktop-theme restore
    else
      $DRY_RUN_CMD ${desktopTheme}/bin/desktop-theme setup
    fi
  '';
  home.packages =
    [
      desktopTheme
      pkgs.papirus-icon-theme
      (pkgs.catppuccin-gtk.override {
        size = "compact";
        variant = "latte";
        accents = ["red" "blue"];
      })
      (pkgs.catppuccin-gtk.override {
        size = "compact";
        variant = "mocha";
        accents = ["red" "blue"];
      })
    ]
    ++ lib.optionals qtEnabled [
      (pkgs.catppuccin-kvantum.override {
        variant = "latte";
        accent = "red";
      })
      (pkgs.catppuccin-kvantum.override {
        variant = "mocha";
        accent = "red";
      })
    ];
  programs.ghostty.settings.theme = "light:Catppuccin Latte Red,dark:Catppuccin Mocha Red";
  systemd.user.services.desktop-theme-restore = {
    Unit = {
      Description = "Restore the selected desktop application theme";
      PartOf = ["graphical-session.target"];
      Before = lib.optionals dunstEnabled ["dunst.service"];
      After = lib.optionals vicinaeEnabled ["vicinae.service"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${desktopTheme}/bin/desktop-theme restore";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
