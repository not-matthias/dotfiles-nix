{
  config,
  lib,
  options,
  pkgs,
  flakes,
  ...
}: {
  options.programs.handy = {
    enable = lib.mkEnableOption "Handy hand-tracking application";
  };

  config = lib.mkIf config.programs.handy.enable (
    {
      home.packages = [
        flakes.handy.packages.${pkgs.system}.handy
        pkgs.wtype # Required for text input on Wayland
      ];
    }
    // lib.optionalAttrs (options.programs ? niri) {
      programs.niri.settings = lib.mkIf config.programs.niri.enable {
        binds."Super+H" = {
          action.spawn = ["handy" "--toggle-transcription"];
          repeat = false;
        };
        binds."Super+Shift+H" = {
          action.spawn = ["handy" "--toggle-post-process"];
          repeat = false;
        };

        spawn-at-startup = [
          {command = ["uwsm" "app" "--" "handy"];}
        ];
      };
    }
  );
}
