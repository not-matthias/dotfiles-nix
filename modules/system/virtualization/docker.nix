# NVIDIA Docker:
# - https://discourse.nixos.org/t/gpu-enabled-docker-containers-in-nixos/23870
# - https://old.reddit.com/r/NixOS/comments/1ctb8w1/state_of_docker_with_nvidia/
# - https://github.com/NVIDIA/nvidia-docker/issues/942
{
  pkgs,
  user,
  lib,
  config,
  ...
}: let
  cfg = config.virtualisation.docker;
in {
  config = lib.mkIf cfg.enable {
    virtualisation = {
      docker = {
        # enable = true;
        autoPrune.enable = true;
      };
    };

    users.groups.docker.members = ["${user}"];

    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    # Allow access from inside docker containers to the host (usually using host.docker.internal/172.17.0.1)
    # based on https://stackoverflow.com/a/52560944
    networking.firewall.extraCommands = ''
      iptables -A INPUT -i br+ -j ACCEPT
      iptables -A INPUT -i docker0 -j ACCEPT
    '';
  };
}
