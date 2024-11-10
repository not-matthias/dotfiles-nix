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
        enableNvidia = true;
      };
    };

    users.groups.docker.members = ["${user}"];

    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}
