# Just for testing purposes
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
    };
    history = {
      size = 10000;
      path = "~/.config/zsh/history";
    };
    # ohMyZsh = {
    #   enable = true;
    #   plugins = ["git" "thefuck"];
    #   theme = "robbyrussell";
    # };
  };
}
