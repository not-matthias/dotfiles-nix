{
  user,
  lib,
  pkgs,
  ...
}: {
  #  This will make all local ports and services unreachable from external connections.
  networking.firewall.enable = true;

  # Rules
  #
  # https://github.com/stusmall/nixos/blob/bbe49deb01250d1d6597dedffc5113c846bc4166/modules/signal.nix
  # https://github.com/dev-null-undefined/NixOs/blob/70fdb7dfb0c89792887d50480de37fb8697eb2be/modules/generated/nixos/services/opensnitch/rules/applications/firefox.nix#L6
  services.opensnitch = {
    enable = false;
    rules = {
      "qutebrowser" = {
        "name" = "qutebrowser";
        "enabled" = true;
        "action" = "allow";
        "duration" = "always";
        "operator" = {
          "type" = "simple";
          "sensitive" = false;
          "operand" = "process.path";
          "data" = "${lib.getBin pkgs.qutebrowser}/bin/qutebrowser";
        };
      };
      "firefox" = {
        "name" = "firefox";
        "enabled" = true;
        "action" = "allow";
        "duration" = "always";
        "operator" = {
          "type" = "simple";
          "sensitive" = false;
          "operand" = "process.path";
          "data" = "${lib.getBin pkgs.firefox}/bin/firefox";
        };
      };
      "nix" = {
        "name" = "nix";
        "enabled" = true;
        "action" = "allow";
        "duration" = "always";
        "operator" = {
          "type" = "simple";
          "sensitive" = false;
          "operand" = "process.path";
          "data" = "${lib.getBin pkgs.nix}/bin/nix";
        };
      };
      "tailscale" = {
        "name" = "tailscale";
        "enabled" = true;
        "action" = "allow";
        "duration" = "always";
        "operator" = {
          "type" = "simple";
          "sensitive" = false;
          "operand" = "process.path";
          "data" = "${pkgs.tailscale}/bin/.tailscaled-wrapped";
        };
      };
    };
  };
  home-manager.users.${user} = {
    home.packages = with pkgs; [
      opensnitch-ui
      qutebrowser
    ];
    services.opensnitch-ui.enable = false;
  };
}
