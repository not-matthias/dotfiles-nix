# NVIDIA Docker:
# - https://discourse.nixos.org/t/gpu-enabled-docker-containers-in-nixos/23870
# - https://old.reddit.com/r/NixOS/comments/1ctb8w1/state_of_docker_with_nvidia/
# - https://github.com/NVIDIA/nvidia-docker/issues/942
{
  pkgs,
  user,
  ...
}: {
  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };

  users.groups.docker.members = ["${user}"];

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
