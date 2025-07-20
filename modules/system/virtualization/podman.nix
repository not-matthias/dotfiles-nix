{pkgs, ...}: {
  virtualisation.podman = {
    #enable = true;
    # dockerCompat = true;
    autoPrune.enable = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [53];

  environment.systemPackages = with pkgs; [
    distrobox
    docker-compose
  ];
}
