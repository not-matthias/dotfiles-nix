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

    programs.ssh.settings."codspeeds-mac-mini codspeeds-mac-mini.tail0bdeec.ts.net" = {
      HostName = "codspeeds-mac-mini.tail0bdeec.ts.net";
      User = "codspeed";
      ForwardAgent = true;
      IdentitiesOnly = true;
      RemoteForward = [
        {
          host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
          bind.address = "/Users/codspeed/.gnupg/S.gpg-agent";
        }
      ];
    };

    programs.fish.functions = {
      cod-staging = ''
        set -gx CODSPEED_API_URL https://gql.staging.preview.codspeed.io/
        set -gx CODSPEED_UPLOAD_URL https://api.staging.preview.codspeed.io/upload
        echo "CodSpeed staging environment activated:"
        echo "  CODSPEED_API_URL=$CODSPEED_API_URL"
        echo "  CODSPEED_UPLOAD_URL=$CODSPEED_UPLOAD_URL"
      '';
      cod-local = ''
        set -gx CODSPEED_API_URL https://7j3xul0pqk.execute-api.eu-west-1.amazonaws.com/dev/
        set -gx CODSPEED_UPLOAD_URL https://aiy2l19wii.execute-api.eu-west-1.amazonaws.com/upload
        echo "CodSpeed local environment activated:"
        echo "  CODSPEED_API_URL=$CODSPEED_API_URL"
        echo "  CODSPEED_UPLOAD_URL=$CODSPEED_UPLOAD_URL"
      '';
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
