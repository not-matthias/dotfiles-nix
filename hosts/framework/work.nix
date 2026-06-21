{
  pkgs,
  user,
  ...
}: {
  home-manager.users.${user} = {...}: {
    home.packages = with pkgs; [
      # Work
      slack
      awscli2
    ];

    programs.ssh.settings."codspeeds-mac-mini" = {
      host = "codspeeds-mac-mini codspeeds-mac-mini.tail0bdeec.ts.net";
      hostname = "codspeeds-mac-mini.tail0bdeec.ts.net";
      user = "codspeed";
      forwardAgent = true;
      identitiesOnly = true;
      remoteForwards = [
        {
          host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
          bind.address = "/Users/codspeed/.gnupg/S.gpg-agent";
        }
      ];
    };
  };

  # Enables the 1Password CLI
  programs._1password = {
    enable = true;
  };

  # Enables the 1Password desktop app
  programs._1password-gui = {
    enable = true;
    # this makes system auth etc. work properly
    polkitPolicyOwners = [user];
  };

  environment.enableDebugInfo = true;
}
