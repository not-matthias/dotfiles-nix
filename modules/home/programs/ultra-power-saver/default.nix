{
  config,
  lib,
  pkgs,
  ...
}: let
  ups = pkgs.writeShellApplication {
    name = "ups";
    runtimeInputs = with pkgs; [
      gnugrep
      gawk
      coreutils
      systemd
      bluez
      auto-cpufreq
      procps
    ];
    text = builtins.readFile ./ultra-power-saver.sh;
  };
in {
  options.programs.ultra-power-saver.enable = lib.mkEnableOption "runtime ultra power saver command";

  config = lib.mkIf config.programs.ultra-power-saver.enable {
    home.packages = [ups];
  };
}
