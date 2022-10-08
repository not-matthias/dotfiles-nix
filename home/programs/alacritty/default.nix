{ pkgs, config, ... }:
{
  home.file.".config/alacritty/alacritty.yml".source = config.lib.file.mkOutOfStoreSymlink ./alacritty.yml;
  programs.alacritty = {
		enable = true;
  };
}