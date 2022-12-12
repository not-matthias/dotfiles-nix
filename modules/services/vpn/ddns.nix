# References:
# - https://cs.github.com/dustinlacewell/dotfiles/blob/1cfb63eb99c320a9cfdbba6c1886ce0c0cba71c1/modules/nixos/services/ddclient.nix?q=noip+language%3Anix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  secrets = builtins.fromTOML (builtins.readFile /tmp/secrets.toml);
in {
  options.ddns.enable = mkEnableOption "Dynamic DNS";
  config = mkIf config.ddns.enable {
    services.ddclient = {
      enable = true;
      protocol = "noip";
      username = secrets.noip-username;
      password = secrets.noip-password;
      server = "dynupdate.no-ip.com";
      domains = ["secrets.noip-hostname"];
    };
  };
}
