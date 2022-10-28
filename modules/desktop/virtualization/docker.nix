{
  config,
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
