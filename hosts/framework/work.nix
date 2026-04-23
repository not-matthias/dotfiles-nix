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
}
