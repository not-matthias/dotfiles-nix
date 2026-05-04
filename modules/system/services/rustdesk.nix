{
  lib,
  pkgs,
  config,
  user,
  ...
}: let
  cfg = config.services.rustdesk-client;
in {
  options.services.rustdesk-client = {
    enable = lib.mkEnableOption "RustDesk client with uinput-based input injection";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.rustdesk-flutter;
      description = "RustDesk package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    # RustDesk injects keyboard/mouse events through /dev/uinput. By default the
    # device is root-only, so input from a remote peer silently no-ops. Load the
    # module and grant the `input` group access.
    boot.kernelModules = ["uinput"];

    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';

    users.users.${user}.extraGroups = ["input"];
  };
}
