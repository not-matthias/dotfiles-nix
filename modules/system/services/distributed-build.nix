{
  config,
  lib,
  user,
  ...
}: let
  cfg = config.services.distributed-build;
  hostName = "pc.ide-snares.ts.net";
in {
  options.services.distributed-build.enable =
    lib.mkEnableOption "offloading Nix builds to remote builders (pc) over Tailscale";

  config = lib.mkIf cfg.enable {
    nix = {
      distributedBuilds = true;
      settings.builders-use-substitutes = true;
      buildMachines = [
        {
          inherit hostName;
          sshUser = user;
          # nix-daemon runs as root and cannot use the user's ssh-agent or ~/.ssh/config.
          sshKey = "/home/${user}/.ssh/id_rsa";
          protocol = "ssh-ng";
          system = "x86_64-linux";
          maxJobs = 8;
          speedFactor = 2;
          supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
          # base64 of pc:/etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUU3WW9GOUZJVU1laFZwUy92d0dXUFFDRU9seGhmUXp2bk5BOTN5Ymd2dlMgcm9vdEBwYw==";
        }
      ];
    };

    # Keep the local fallback fast when Tailscale is down.
    programs.ssh.extraConfig = ''
      Host ${hostName}
        ConnectTimeout 5
    '';
  };
}
