{
  config,
  lib,
  options,
  pkgs,
  ...
}: {
  options.programs.handy = {
    enable = lib.mkEnableOption "Handy hand-tracking application";
  };

  config = lib.mkIf config.programs.handy.enable (
    {
      home.packages = with pkgs; [
        handy
        wtype # Required for text input on Wayland
      ];
    }
    // lib.optionalAttrs (options.programs ? niri) {
      programs.niri.settings = lib.mkIf config.programs.niri.enable {
        binds."Super+H".action.spawn = ["handy"];

        spawn-at-startup = [
          {command = ["uwsm" "app" "--" "handy"];}
        ];
      };
    }
  );
}
