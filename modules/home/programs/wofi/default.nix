# https://github.com/notusknot/dotfiles-nix/blob/a034dcb6daff31ce50cdbc74a5972b1ef56ef3d7/modules/wofi/default.nix
# https://cloudninja.pw/docs/wofi.html
# https://man.archlinux.org/man/wofi.5
{pkgs, ...}: {
  home.packages = with pkgs; [
    wofi
  ];
  home.file.".config/wofi/config".text = ''
    prompt=Search...
    width=280

    gtk_dark=true
    insensitive=true
    lines=10
  '';
}
